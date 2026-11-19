class_name OddEvenViews
extends ExtensionViews
## The views on the `odd-even` situation (FAL-1007): one builder per unknown of
## fn-ahl-odd-even (AHL2.14). Odd, even or neither is a `claim` with its reason; a
## coefficient, a value and an integral are exact numbers; completing a graph and
## choosing one are pick-the-graph (GdcKit.pick), each wrong card a named mistake.
## Every cell makes both papers: the numbers need no calculator, and on Paper 2 an
## integral given from 0 to a may be a decimal.

const S := preload("res://engine/situations/odd_even.gd")

const R_NOT_EVEN := "AHL2.14.odd-even-test#0"
const R_ODD_POWERS := "AHL2.14.odd-even-test#1"
const R_ONE_VALUE := "AHL2.14.odd-even-test#2"
const R_Y_AXIS := "AHL2.14.odd-even-graph#0"
const R_X_AXIS := "AHL2.14.odd-even-graph#1"
const R_OFF_ORIGIN := "AHL2.14.odd-even-graph#2"
const R_ODD_ODD := "AHL2.14.odd-even-combine#0"
const R_SUM := "AHL2.14.odd-even-combine#1"
const R_EVEN_ZERO := "AHL2.14.odd-even-combine#2"
const R_ODD_DOUBLED := "fn-ahl-odd-even#9"
const R_SWAPPED := "fn-ahl-odd-even#10"
const R_EVEN_NEGATED := "fn-ahl-odd-even#11"
const R_OTHER_POWERS := "fn-ahl-odd-even#12"

const ODD := "Odd: f(−x) = −f(x)"
const EVEN := "Even: f(−x) = f(x)"
const NEITHER := "Neither: f(−x) is not f(x) or −f(x)"
const SW_EVEN := "Even: f(−x) = −f(x)"
## The swap the other way: a filler, as #10's text names reading −f(x) as even.
const SW_ODD := "Odd: f(−x) = f(x)"
const NOT_EQ := "Odd: f(−x) is not f(x)"
const ODD_POWERS := "Odd: every power of x in it is odd"
const AT_PI := "Even: f(−π) = f(π)"
const SUM_EVEN := "Even: an odd part plus an even part is even"
const SUM_ODD := "Odd: an odd part plus an even part is odd"
const H_ODD := "Odd: h(−x) = −h(x)"
const H_EVEN := "Even: h(−x) = h(x)"
const H_NEITHER := "Neither: h(−x) is not h(x) or −h(x)"
const H_ODD_ODD := "Odd: odd × odd is odd"
const H_SUM_ODD := "Odd: odd + even is odd"
const H_SUM_EVEN := "Even: odd + even is even"
const WIN_X := 8


func needs() -> Dictionary:
	return {
		"classify-polynomial": {"ask": "classify-polynomial"},
		"classify-mixed": {"ask": "classify-mixed"},
		"symmetry-coefficient": {"ask": "symmetry-coefficient"},
		"value-from-symmetry": {"ask": "value-from-symmetry"},
		"complete-graph": {"ask": "complete-graph"},
		"which-graph": {"ask": "which-graph"},
		"combine-parity": {"ask": "combine-parity"},
		"symmetric-integral": {"ask": "symmetric-integral"},
	}


## No cell needs a calculator, so every cell makes both papers in the exam's ratio.
func papers(unknown: String, _rep: String, _angle: String) -> Array:
	return [1, 2] if has(unknown) else []


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = S.export(s)
	return out


# ── Writing functions ────────────────────────────────────────

static func G(g: String) -> String:
	return {"sin": "sin x", "cos": "cos x", "exp": "e^x", "nexp": "e^(−x)"}.get(g, "")


## A term without its sign: "3x² sin x", "sin x", "4", "e^(−x)".
static func body(c: int, p: int, g: String) -> String:
	var mag := absi(c)
	var xp: String = "" if p == 0 else "x" + Fmt.sup(p)
	if g in ["exp", "nexp"]:
		return ("" if mag == 1 else str(mag)) + G(g)
	if g == "":
		return str(mag) if p == 0 else ("" if mag == 1 else str(mag)) + xp
	var lead: String = "" if mag == 1 else str(mag)
	if xp == "":
		return (lead + " " if lead != "" else "") + G(g)
	return lead + xp + " " + G(g)


## Terms joined with their signs: "x³ − 4x + 5".
static func ftext(terms: Array) -> String:
	var out := ""
	for t in terms:
		var c := int(t.c)
		if c == 0:
			continue
		var b := body(c, int(t.p), t.g)
		if out == "":
			out = ("−" if c < 0 else "") + b
		else:
			out += (" − " if c < 0 else " + ") + b
	return out if out != "" else "0"


## f(−x) before simplifying: "3(−x)² sin(−x) − 2(−x) + 5". e^x and e^(−x) are written
## already swapped, as e^(−x) and e^x.
static func raw_minus(terms: Array) -> String:
	var out := ""
	for t in terms:
		var c := int(t.c)
		var p := int(t.p)
		var mag := absi(c)
		var b: String
		if t.g == "exp":
			b = ("" if mag == 1 else str(mag)) + "e^(−x)"
		elif t.g == "nexp":
			b = ("" if mag == 1 else str(mag)) + "e^x"
		elif p == 0 and t.g == "":
			b = str(mag)
		else:
			var lead: String = "" if mag == 1 else str(mag)
			var xp: String = "" if p == 0 else "(−x)" + Fmt.sup(p)
			var gp: String = "" if t.g == "" else t.g + "(−x)"
			b = lead + xp + (" " if xp != "" and gp != "" else "") + gp
			if lead != "" and xp == "":
				b = lead + " " + gp
		if out == "":
			out = ("−" if c < 0 else "") + b
		else:
			out += (" − " if c < 0 else " + ") + b
	return out


static func negated(terms: Array) -> Array:
	return terms.map(func(t): return S.term(-int(t.c), t.p, t.g))


## A value as 1, sin a, cos a, e^a, e^(−a) with whole coefficients: "2 + 3 sin 1 − e".
static func vtext(v: Dictionary, a: int) -> String:
	var n := absi(a)
	var names := {"1": "", "sin": "sin %d" % n, "cos": "cos %d" % n, "exp": "e" + ("" if n == 1 else Fmt.sup(n)), "nexp": "e^(−%d)" % n}
	var out := ""
	for k in ["1", "sin", "cos", "exp", "nexp"]:
		var c := int(v[k])
		if c == 0:
			continue
		var mag := absi(c)
		var b: String
		if k == "1":
			b = str(mag)
		elif k in ["sin", "cos"]:
			b = ("" if mag == 1 else "%d " % mag) + names[k]
		else:
			b = ("" if mag == 1 else str(mag)) + names[k]
		if out == "":
			out = ("−" if c < 0 else "") + b
		else:
			out += (" − " if c < 0 else " + ") + b
	return out if out != "" else "0"


static func claim(text: String) -> Dictionary:
	return {"form": text, "vals": [], "text": text}


static func number(label: String, v: Q, dec: bool = false) -> Dictionary:
	var ans := Answer.make("number", {"v": v}, {}, label)
	ans.exact = true
	if dec:
		ans.show = "dec"
	return ans


static func steps_to(m: Dictionary, last: String, ans: Dictionary) -> Dictionary:
	var out := {}
	for a in m:
		out[a] = method(m[a] + [last], ans.values)
	return out


## A claim question's answer, its tagged slips (shuffled) and its fillers.
static func claims(right: String, tagged: Array, plain: Array, rng: Seeded) -> Dictionary:
	var seen := {right: true}
	var ws: Array = []
	for t in rng.shuffled(tagged):
		if not seen.has(t[0]):
			seen[t[0]] = true
			ws.append(wrong(claim(t[0]), t[1]))
	var fill: Array = []
	for p in plain:
		if not seen.has(p):
			seen[p] = true
			fill.append(claim(p))
	return {"answer": Answer.make("claim", claim(right)), "wrongs": ws, "fillers": fill}


static func verdict(parity: String) -> String:
	return {"odd": ODD, "even": EVEN, "neither": NEITHER}[parity]


# ── Odd, even or neither ─────────────────────────────────────

func u_classify_polynomial(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _classify(rep, s, rng, false)


func u_classify_mixed(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _classify(rep, s, rng, true)


## Why one term is odd or even, for the building-blocks working.
static func why_term(t: Dictionary) -> String:
	var name := ftext([t])
	var p := int(t.p)
	var even := S.term_parity(t) > 0
	var kind := "even" if even else "odd"
	if t.g == "":
		return "%s is %s (%s)" % [name, kind, "a constant" if p == 0 else ("an even power" if p % 2 == 0 else "an odd power")]
	var g_kind := "odd" if t.g == "sin" else "even"
	if p == 0:
		return "%s is %s" % [name, kind]
	return "%s is %s × %s = %s" % [name, "even" if p % 2 == 0 else "odd", g_kind, kind]


## The exp pair's line, for the building-blocks working.
static func why_exp(terms: Array) -> String:
	var a := 0
	var b := 0
	for t in terms:
		if t.g == "exp":
			a = int(t.c)
		elif t.g == "nexp":
			b = int(t.c)
	var pair := ftext(terms.filter(func(t): return t.g in ["exp", "nexp"]))
	if a == b:
		return "%s is even: x → −x swaps e^x and e^(−x), and their coefficients are equal" % pair
	if a == -b:
		return "%s is odd: x → −x swaps e^x and e^(−x), and their coefficients are opposite" % pair
	return "%s is neither: x → −x swaps e^x and e^(−x), and their coefficients are not equal or opposite" % pair


func _classify(_rep: String, s: Dictionary, rng: Seeded, mixed: bool) -> Dictionary:
	var terms: Array = s.terms
	var par: String = s.parity
	var right := verdict(par)
	var tagged: Array = []
	var plain: Array = []
	match par:
		"odd":
			tagged.append([SW_EVEN, R_SWAPPED])
			if mixed and s.at_pi:
				tagged.append([AT_PI, R_ONE_VALUE])
			plain = [NEITHER, EVEN]
		"even":
			plain = [NEITHER, ODD, SW_ODD]
		_:
			tagged.append([NOT_EQ, R_NOT_EVEN])
			if not mixed and s.oddconst:
				tagged.append([ODD_POWERS, R_ODD_POWERS])
			if not mixed:
				tagged.append([SUM_EVEN if rng.chance(0.5) else SUM_ODD, R_SUM])
			if mixed and s.at_pi:
				tagged.append([AT_PI, R_ONE_VALUE])
			plain = [EVEN, ODD]
	var out := claims(right, tagged, plain, rng)
	var ft := ftext(terms)
	out.lines = ["f(x) = " + ft]
	out.asked = "Is f odd, even or neither, and why?"
	var minus := ftext(S.at_minus(terms))
	var compare: String
	match par:
		"odd":
			compare = "That is −(%s) = −f(x)" % ft
		"even":
			compare = "That is f(x)"
		_:
			compare = "That is not f(x), and not −f(x) = %s" % ftext(negated(terms))
	var last := "So: %s." % right
	var m := {}
	var raw := raw_minus(terms)
	m["substitute-minus-x"] = ["Put −x in: f(−x) = " + raw] + (["Simplify: f(−x) = " + minus] if raw != minus else []) + [compare]
	# The building blocks: one line naming each term's parity, then what the sum is.
	var whys: Array = terms.filter(func(t): return t.g not in ["exp", "nexp"]).map(func(t): return why_term(t))
	if terms.any(func(t): return t.g in ["exp", "nexp"]):
		whys.append(why_exp(terms))
	var sum_line: String = {"odd": "Every piece is odd, and a sum of odd functions is odd", "even": "Every piece is even, and a sum of even functions is even",
		"neither": "f is a non-zero odd part plus a non-zero even part, and such a sum is neither odd nor even"}[par]
	m["known-building-blocks"] = ["; ".join(whys), sum_line]
	if par == "neither":
		var a: int = s.ctr
		var up := S.value_at(terms, a)
		var down := S.value_at(terms, -a)
		var neg := {}
		for k in up:
			neg[k] = -int(up[k])
		m["counterexample"] = ["Try x = %d: f(%d) = %s and f(−%d) = %s" % [a, a, vtext(up, a), a, vtext(down, a)],
			"f(−%d) ≠ f(%d), so f is not even" % [a, a], "f(−%d) ≠ −f(%d) = %s, so f is not odd" % [a, a, vtext(neg, a)]]
	if mixed and terms.any(func(t): return t.g in ["sin", "cos"]):
		m["unit-circle"] = ["On the unit circle, the angle −x is the mirror image of x in the horizontal axis: cos(−x) = cos x and sin(−x) = −sin x",
			"So f(−x) = " + minus, compare]
	out.methods = steps_to(m, last, out.answer)
	return out


# ── A coefficient ────────────────────────────────────────────

## (k − r) as a coefficient: "(k − 3)", "(k + 2)", "k".
static func kco(r: int) -> String:
	if r == 0:
		return "k"
	return "(k %s %d)" % ["−" if r > 0 else "+", absi(r)]


## k − r as an expression: "k − 3", "k + 2".
static func kexpr(r: int) -> String:
	return "k" if r == 0 else "k %s %d" % ["−" if r > 0 else "+", absi(r)]


## The rule with k in it, highest power first; sign −1 writes f(−x).
static func ktext(s: Dictionary, sign: int = 1) -> String:
	var items: Array = []
	for t in s.terms:
		items.append({"p": int(t.p), "c": int(t.c) * (1 if sign > 0 or int(t.p) % 2 == 0 else -1), "k": false})
	for t in s.kt:
		items.append({"p": int(t.p), "r": int(t.r), "neg": sign < 0 and int(t.p) % 2 == 1, "k": true})
	items.sort_custom(func(a, b): return a.p > b.p)
	var out := ""
	for it in items:
		var xp: String = "" if it.p == 0 else "x" + Fmt.sup(it.p)
		if it.k:
			var b: String = kco(it.r) + xp
			if out == "":
				out = ("−" if it.neg else "") + b
			else:
				out += (" − " if it.neg else " + ") + b
		else:
			var b := body(it.c, it.p, "")
			if out == "":
				out = ("−" if it.c < 0 else "") + b
			else:
				out += (" − " if it.c < 0 else " + ") + b
	return out


static func power_name(p: int) -> String:
	return "constant" if p == 0 else "x" + Fmt.sup(p)


func u_symmetry_coefficient(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var odd: bool = s.target == "odd"
	var bad: Dictionary = s.kt[0]
	var good: Dictionary = s.kt[1]
	var k := int(bad.r)
	var ans := number("k = ", Q.new(k))
	var out := {"lines": ["f(x) = " + ktext(s), "f is an %s function." % s.target], "asked": "Find the value of k.", "answer": ans,
		"wrongs": [wrong({"v": Q.new(int(good.r))}, R_OTHER_POWERS)],
		"fillers": [{"v": Q.new(-k)}, {"v": Q.new(-int(good.r))}, {"v": Q.new(k + 1)}]}
	var kind := "even" if odd else "odd"
	var term_name := power_name(int(bad.p))
	var term_text: String = "the constant term" if int(bad.p) == 0 else "the %s term" % term_name
	var then := "Then f(x) = %s, with only %s powers" % [ftext(S.with_k(s, k)), "odd" if odd else "even"]
	var zero := "%s, %s, must be 0: %s = 0" % [term_text, kco(int(bad.r)) + ("" if int(bad.p) == 0 else term_name), kexpr(int(bad.r))]
	var m := {
		"substitute-minus-x": ["Put −x in: f(−x) = " + ktext(s, -1),
			"f(−x) = %s for every x only if each %s power has a coefficient of 0, so %s" % ["−f(x)" if odd else "f(x)", kind, zero], then],
		"known-building-blocks": ["Odd powers are odd functions; even powers and constants are even functions",
			"f is %s only if it has no %s part, so %s" % [s.target, kind, zero], then],
	}
	out.methods = steps_to(m, "So %s." % Answer.text(ans), ans)
	return out


# ── A value from the symmetry ────────────────────────────────

static func expr_text(a: int, m: int) -> String:
	match m:
		1:
			return "f(%d) + f(−%d)" % [a, a]
		-1:
			return "f(−%d) − f(%d)" % [a, a]
		2:
			return "f(−%d) + 2f(%d)" % [a, a]
	return "f(−%d)" % a


## The half's curve as floats.
static func curve(pts: Array) -> Array:
	return pts.map(func(p): return [float(p[0]), float(p[1])])


## The window for curves: x from −8 to 8, y round every point.
static func window(curves: Array) -> Array:
	var top := 2
	for c in curves:
		for p in c:
			top = maxi(top, ceili(absf(p[1])))
	return [-WIN_X, WIN_X, -(top + 1), top + 1]


func u_value_from_symmetry(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	var mm: int = s.m
	var odd: bool = s.parity == "odd"
	var fma := -b if odd else b
	var v := Q.new(fma + mm * b)
	var ex := expr_text(a, mm)
	var ans := number(ex + " = ", v)
	var slip := Q.new((b if odd else -b) + mm * b)
	var out := {"asked": "Find %s." % ex, "answer": ans, "wrongs": [wrong({"v": slip}, R_Y_AXIS if odd else R_EVEN_NEGATED)],
		"fillers": [{"v": v.neg()}, {"v": Q.new(b * (mm + 2))}, {"v": Q.new(-b * (mm + 2))}, {"v": Q.new(0)}]}
	var know: String
	var names: String = "p, q and r" if String(s.get("form", "")).contains("r") else "p and q"
	if rep == "graph":
		out.lines = ["The graph of y = f(x) for x ≥ 0 is shown. f is %s." % s.parity]
		var g := Plot.spec([curve(s.half)], [[a, b, Fmt.point(a, b)]], -1, WIN_X, -(S.Y_MAX + 1), S.Y_MAX + 1)
		g.one_colour = true
		out.graph = g
		know = "The graph passes through (%d, %s), so f(%d) = %s" % [a, N(b), a, N(b)]
	else:
		out.lines = ["f(x) = %s, where %s are constants, and f(%d) = %s." % [s.form, names, a, N(b)]]
		know = "Each term of f is %s, so f is %s whatever %s are" % [s.parity, s.parity, names]
	var img := "f(−%d) = %s" % [a, N(fma)]
	var steps_sum: Array = []
	match mm:
		1:
			steps_sum = ["%s = %s + %s = %s" % [ex, N(b), P(fma), N(v)]]
		-1:
			steps_sum = ["%s = %s − %s = %s" % [ex, N(fma), P(b), N(v)]]
		2:
			steps_sum = ["%s = %s + 2 × %s = %s" % [ex, N(fma), P(b), N(v)]]
	var rot: String = "f is odd: its graph is unchanged by a half-turn about the origin, so (%d, %s) goes to (−%d, %s)" % [a, N(b), a, N(-b)] if odd \
		else "f is even: its graph is its own mirror image in the y-axis, so (%d, %s) goes to (−%d, %s)" % [a, N(b), a, N(b)]
	var pts: String = ("f is odd, so f(−x) = −f(x): each point (x, y) has the image (−x, −y), and (%d, %s) has the image (−%d, %s)" if odd \
		else "f is even, so f(−x) = f(x): each point (x, y) has the image (−x, y), and (%d, %s) has the image (−%d, %s)") % [a, N(b), a, N(fma)]
	var m := {
		"reflect-or-rotate": [know, rot, img] + steps_sum,
		"image-points": [know, pts, img] + steps_sum,
	}
	if mm == 0:
		for k in m:
			m[k] = m[k].slice(0, -1)
	out.methods = steps_to(m, "So %s." % Answer.text(ans), ans)
	return out


# ── Completing a graph ───────────────────────────────────────

## The whole graph from a half: one curve through the origin side, or two pieces.
static func whole(half: Array, odd: bool) -> Array:
	var left: Array = S.other_half(half, odd)
	left.reverse()
	return [curve(left + half.slice(1))] if int(left[-1][1]) == int(half[0][1]) else [curve(left), curve(half)]


static func dots(curves: Array) -> Array:
	var out: Array = []
	for c in curves:
		for p in c:
			out.append([p[0], p[1], ""])
	return out


static func card(curves: Array, win: Array) -> Dictionary:
	var g := GdcKit.card(curves, dots(curves), win)
	g.one_colour = true
	return g


func u_complete_graph(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var half: Array = s.half
	var odd: bool = s.parity == "odd"
	var k: int = s.k
	var right := whole(half, odd)
	var mirror := whole(half, false)
	var turn := whole(half, true)
	var x_axis := [curve(half), curve(half.map(func(p): return [p[0], -int(p[1])]))]
	var off: Array = half.map(func(p): return [-int(p[0]), 2 * k - int(p[1])])
	off.reverse()
	var off_c := [curve(off), curve(half)]
	var w: int = int(half[-1][0])
	var slid := [curve(half.map(func(p): return [int(p[0]) - w, p[1]])), curve(half)]
	var win := window(right + mirror + turn + x_axis + off_c)
	var wrongs: Array
	if odd:
		wrongs = [{"graph": card(mirror, win), "ref": R_Y_AXIS, "mistake": "y-axis", "why": "this mirrors the half in the y-axis, which makes f even, not odd"},
			{"graph": card(x_axis, win), "ref": R_X_AXIS, "mistake": "x-axis", "why": "this mirrors the half in the x-axis, which gives two y-values for each x > 0 and nothing for x < 0"},
			{"graph": card(off_c, win), "ref": R_OFF_ORIGIN, "mistake": "off-origin", "why": "this turns the half about a point on the y-axis other than the origin, so f(0) is not 0"}]
	else:
		wrongs = [{"graph": card(turn, win), "ref": "", "mistake": "half-turn", "why": "this turns the half about the origin, which makes f odd, not even"},
			{"graph": card(x_axis, win), "ref": "", "mistake": "x-axis", "why": "this mirrors the half in the x-axis, which gives two y-values for each x > 0 and nothing for x < 0"},
			{"graph": card(slid, win), "ref": "", "mistake": "slide", "why": "this slides the half to the left instead of mirroring it in the y-axis"}]
	var picked := GdcKit.pick(card(right, win), wrongs, rng)
	var ans: Dictionary = picked.answer
	var g := Plot.spec([curve(half)], half.map(func(p): return [p[0], p[1], Fmt.point(p[0], p[1])]), -WIN_X, WIN_X, win[2], win[3])
	g.one_colour = true
	var out := {"asked": "Which graph shows y = f(x) for every x?", "answer": ans, "graphs": picked.graphs, "graph": g,
		"lines": ["The graph of y = f(x) for x ≥ 0 is shown. f is %s and defined for every x." % s.parity]}
	var imgs: Array = half.slice(1).map(func(p): return "%s to %s" % [Fmt.point(p[0], p[1]), Fmt.point(-int(p[0]), -int(p[1]) if odd else int(p[1]))])
	var last := "The graph that does this is %s. So %s." % [picked.letter, picked.letter]
	var m := {
		"reflect-or-rotate": ["f is odd, so its graph is unchanged by a half-turn (180°) about the origin" if odd else "f is even, so its graph is its own mirror image in the y-axis",
			"Turn the half for x ≥ 0 about the origin: it lands in x ≤ 0 and joins it at (0, 0)" if odd else "Mirror the half for x ≥ 0 in the y-axis: it lands in x ≤ 0 and joins it at %s" % Fmt.point(0, half[0][1])],
		"image-points": ["Each key point (x, y) goes to %s" % ("(−x, −y)" if odd else "(−x, y)"), "; ".join(imgs), "Join the images in the same shape"],
	}
	out.methods = steps_to(m, last, ans)
	return out


# ── Which graph ──────────────────────────────────────────────

func u_which_graph(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var odd: bool = s.parity == "odd"
	var hs: Array = s.halves
	var right := whole(hs[0], odd)
	var other := whole(hs[1], not odd)
	var shifted: Array
	if odd:
		shifted = whole(hs[2], true).map(func(c): return c.map(func(p): return [p[0], p[1] + float(s.k)]))
	else:
		shifted = whole(hs[2], false).map(func(c): return c.map(func(p): return [p[0] + float(s.h), p[1]]))
	var left: Array = s.left.map(func(p): return [-int(p[0]), p[1]])
	left.reverse()
	var neither := [curve(left + hs[3].slice(1))]
	var win := window(right + other + shifted + neither)
	var wrongs: Array
	if odd:
		wrongs = [{"graph": card(other, win), "ref": R_Y_AXIS, "mistake": "even", "why": "this graph is its own mirror image in the y-axis, so it is even"},
			{"graph": card(shifted, win), "ref": "", "mistake": "shifted", "why": "this graph has a half-turn about a point on the y-axis, not about the origin"},
			{"graph": card(neither, win), "ref": "", "mistake": "neither", "why": "this graph has neither symmetry"}]
	else:
		wrongs = [{"graph": card(other, win), "ref": "", "mistake": "odd", "why": "this graph is unchanged by a half-turn about the origin, so it is odd"},
			{"graph": card(shifted, win), "ref": "", "mistake": "shifted", "why": "this graph is a mirror image in a vertical line, but not in the y-axis"},
			{"graph": card(neither, win), "ref": "", "mistake": "neither", "why": "this graph has neither symmetry"}]
	var picked := GdcKit.pick(card(right, win), wrongs, rng)
	var ans: Dictionary = picked.answer
	var out := {"asked": "Which graph shows an %s function?" % s.parity, "answer": ans, "graphs": picked.graphs,
		"lines": ["Four graphs are shown."]}
	var test: String = "An odd function's graph is unchanged by a half-turn (180°) about the origin" if odd else "An even function's graph is its own mirror image in the y-axis"
	var notes: Array = []
	for gr in picked.graphs:
		if not gr.correct:
			notes.append("%s %s" % [gr.text, gr.why.trim_prefix("this graph ")])
	var m := {"reflect-or-rotate": [test, "%s passes that test. %s" % [picked.letter, "; ".join(notes)]]}
	out.methods = steps_to(m, "So %s." % picked.letter, ans)
	return out


# ── Combining odd and even functions ─────────────────────────

static func op_text(op: String) -> String:
	return {"product": "h(x) = f(x)g(x)", "sum": "h(x) = f(x) + g(x)", "fg": "h(x) = f(g(x))", "gf": "h(x) = g(f(x))"}[op]


## f(−x) as its parity gives it: "−f(x)" or "f(x)"; for an inner value, "−g(x)".
static func flip(name: String, p: String) -> String:
	return ("−" if p == "odd" else "") + name + "(x)"


func u_combine_parity(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var pf: String = s.pf
	var pg: String = s.pg
	var op: String = s.op
	var par: String = s.parity
	var right: String = {"odd": H_ODD, "even": H_EVEN, "neither": H_NEITHER}[par]
	var tagged: Array = []
	if op == "product" and pf == "odd" and pg == "odd":
		tagged.append([H_ODD_ODD, R_ODD_ODD])
	if op == "sum" and pf != pg:
		tagged.append([H_SUM_ODD, R_SUM])
		tagged.append([H_SUM_EVEN, R_SUM])
	# The fourth option, where no slip fills it: the verdict with the other definition.
	var swapped: String = {"odd": "Even: h(−x) = −h(x)", "even": "Odd: h(−x) = h(x)", "neither": "Odd: h(−x) = h(x)"}[par]
	var out := claims(right, tagged, [H_NEITHER, H_EVEN, H_ODD, swapped], rng)
	var who: String = "f and g are both %s functions" % pf if pf == pg else "f is an %s function and g is an %s function" % [pf, pg]
	out.lines = [who + ", and neither is 0 for every x.", op_text(op)]
	out.asked = "Is h odd, even or neither?"
	var proof: Array
	match op:
		"product":
			var signs := "(%s)(%s)" % [flip("f", pf), flip("g", pg)]
			proof = ["h(−x) = f(−x)g(−x) = " + signs, "= %sf(x)g(x) = %s" % ["−" if par == "odd" else "", "−h(x)" if par == "odd" else "h(x)"]]
		"sum":
			var both := "%s + %s" % [flip("f", pf), flip("g", pg)]
			proof = ["h(−x) = f(−x) + g(−x) = " + both.replace("+ −", "− ")]
			if par == "odd":
				proof.append("= −(f(x) + g(x)) = −h(x)")
			elif par == "even":
				proof.append("= f(x) + g(x) = h(x)")
			else:
				proof.append("That is h(x) only if f(x) = 0 for every x, and −h(x) only if g(x) = 0 for every x")
		"fg":
			if pg == "even":
				proof = ["h(−x) = f(g(−x)) = f(g(x)), since g(−x) = g(x)", "= h(x)"]
			else:
				proof = ["h(−x) = f(g(−x)) = f(−g(x)), since g is odd", "= −f(g(x)) = −h(x), since f is odd" if pf == "odd" else "= f(g(x)) = h(x), since f is even"]
		"gf":
			if pf == "even":
				proof = ["h(−x) = g(f(−x)) = g(f(x)), since f(−x) = f(x)", "= h(x)"]
			else:
				proof = ["h(−x) = g(f(−x)) = g(−f(x)), since f is odd", "= −g(f(x)) = −h(x), since g is odd" if pg == "odd" else "= g(f(x)) = h(x), since g is even"]
	var m := {"general-proof": proof}
	if op == "product":
		var sv := func(p: String) -> String: return "(−1)" if p == "odd" else "(+1)"
		m["sign-rule"] = ["Count an odd function as −1 and an even one as +1, and multiply",
			"h = f × g: %s × %s = %s, which is %s" % [sv.call(pf), sv.call(pg), "+1" if par == "even" else "−1", par]]
	out.methods = steps_to(m, "So: %s." % right, out.answer)
	return out


# ── An integral from −a to a ─────────────────────────────────

static func itext(lo: String, hi: String, f: String) -> String:
	return "∫ from %s to %s of %s dx" % [lo, hi, f]


static func D(v: Q, dec: bool) -> String:
	return Fmt.dec(v) if dec else N(v)


## D, bracketed when negative.
static func PD(v: Q, dec: bool) -> String:
	return "(%s)" % D(v, dec) if v.sign() < 0 else D(v, dec)


## The antiderivative of polynomial terms: "x³ + 4x", "(2/5)x⁵ − x".
static func anti(terms: Array) -> String:
	var cs: Array = []
	var ps: Array = []
	for t in terms:
		cs.append(Q.new(int(t.c), int(t.p) + 1))
		ps.append(int(t.p) + 1)
	return Fmt.terms(cs, ps)


func u_symmetric_integral(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var I: Q = s.I
	var dec: bool = s.paper == 2 and s.mode == "given"
	var lo := "−%d" % a
	var whole_int := itext(lo, str(a), "f(x)")
	var half_int := itext("0", str(a), "f(x)")
	var out := {"asked": "Find %s." % whole_int}
	var v: Q
	var m := {}
	var wrongs: Array = []
	var fillers: Array = []
	if s.mode in ["given", "graph"]:
		var odd: bool = s.parity == "odd"
		v = Q.new(0) if odd else I.mul(2)
		var shown := D(I, dec)
		if rep == "graph":
			var curves := whole(s.half, odd)
			var g := Plot.spec(curves, [], -WIN_X, WIN_X, -(S.Y_MAX + 1), S.Y_MAX + 1)
			g.one_colour = true
			var f := func(x: float) -> float: return _poly_at(s.half, x)
			g.shade = [DefiniteIntegralViews.under(f, 0.0, float(a))]
			out.graph = g
			out.lines = ["The graph of y = f(x) is shown for −%d ≤ x ≤ %d. The shaded region, between the curve and the x-axis from x = 0 to x = %d, has area %s." % [a, a, a, shown]]
		else:
			out.lines = ["f is an %s function, and %s = %s." % [s.parity, half_int, shown]]
		wrongs = [wrong({"v": I.mul(2)}, R_ODD_DOUBLED)] if odd else [wrong({"v": Q.new(0)}, R_EVEN_ZERO)]
		fillers = [{"v": I}, {"v": I.mul(-2)}, {"v": I.neg()}]
		var known: String = ("The graph is unchanged by a half-turn about the origin, so f is odd" if odd else "The graph is its own mirror image in the y-axis, so f is even") \
			if rep == "graph" else ("f is odd, so f(−x) = −f(x)" if odd else "f is even, so f(−x) = f(x)")
		var given_line: String = "The area from 0 to %d is %s, and the curve is above the x-axis there, so %s = %s" % [a, shown, half_int, shown] if rep == "graph" \
			else "%s = %s" % [half_int, shown]
		var left_v: String = D(I.neg(), dec) if odd else shown
		var sum_line: String = "%s = %s + %s = %s" % [whole_int, PD(I.neg(), dec), PD(I, dec), D(v, dec)] if odd \
			else "%s = 2 × %s = %s" % [whole_int, PD(I, dec), D(v, dec)]
		m["symmetric-area"] = [known + ("" if rep == "graph" else ": " + ("its graph from −%d to 0 is the half from 0 to %d turned about the origin" % [a, a] if odd else "its graph from −%d to 0 mirrors the half from 0 to %d" % [a, a])),
			"%s = %s" % [itext(lo, "0", "f(x)"), left_v] + (", the half's signed area turned upside down" if odd else ", the same as the half"), sum_line]
		if rep == "graph":
			m["symmetric-area"] = [known, given_line] + m["symmetric-area"].slice(1)
		var sign_line: String = "Odd counts as −1: f(−x) = −f(x), so the integral from −%d to 0 is −(%s)" % [a, half_int] if odd \
			else "Even counts as +1: f(−x) = f(x), so the integral from −%d to 0 equals %s" % [a, half_int]
		m["sign-rule"] = [known, sign_line, sum_line] if rep != "graph" else [known, given_line, sign_line, sum_line]
	else:
		var odd_t: Array = s.odd
		var even_t: Array = s.even
		var all: Array = S._ordered(odd_t + even_t)
		var ft := ftext(all)
		out.lines = ["f(x) = " + ft]
		v = I.mul(2)
		if not even_t.is_empty():
			wrongs.append(wrong({"v": Q.new(0)}, R_EVEN_ZERO))
		if not odd_t.is_empty() and odd_t.all(func(t): return t.g == ""):
			var oi := S.half_integral(odd_t, a)
			if not oi.is_zero():
				wrongs.append(wrong({"v": oi.add(I).mul(2)}, R_ODD_DOUBLED))
		fillers = [{"v": I}, {"v": v.neg()}, {"v": v.add(Q.new(2 * a))}, {"v": Q.new(2 * a)}]
		var odd_names := ftext(odd_t)
		var even_names := ftext(even_t)
		var even_sum: Array
		if even_t.is_empty():
			even_sum = ["There are no even terms, so %s = 0" % whole_int]
		else:
			var at_a := "2 × [%s] from 0 to %d = 2 × %s = %s" % [anti(even_t), a, P(I), N(v)]
			even_sum = ["The even terms give twice their integral from 0 to %d: 2 × %s" % [a, itext("0", str(a), "(%s)" % even_names if even_t.size() > 1 else even_names)], at_a]
		var odd_line: String = "The odd terms, %s, cancel: each has as much area below the x-axis on one side of the y-axis as above it on the other" % odd_names
		var parts: Array = []
		if not odd_t.is_empty():
			parts.append(odd_line)
		m["symmetric-area"] = parts + even_sum
		var signs: Array = all.map(func(t): return why_term(t))
		var sign_odd: String = "So the odd terms integrate to 0 from −%d to %d" % [a, a]
		m["sign-rule"] = ["Odd counts as −1 and even as +1: " + "; ".join(signs)] + ([sign_odd] if not odd_t.is_empty() else []) + even_sum
	out.answer = number(whole_int + " = ", v, dec)
	out.wrongs = wrongs
	out.fillers = fillers
	out.methods = steps_to(m, "So %s." % Answer.text(out.answer), out.answer)
	return out


## The polyline's height at x (the whole graph, from the half's symmetry is not needed:
## only x from 0 to a is shaded).
static func _poly_at(half: Array, x: float) -> float:
	for i in range(1, half.size()):
		var x0 := float(half[i - 1][0])
		var x1 := float(half[i][0])
		if x <= x1 + 1e-9:
			var t := (x - x0) / (x1 - x0)
			return float(half[i - 1][1]) + t * (float(half[i][1]) - float(half[i - 1][1]))
	return float(half[-1][1])
