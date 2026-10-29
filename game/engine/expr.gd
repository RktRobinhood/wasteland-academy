class_name Expr
extends RefCounted
## The expression engine (FAL-419): reads what a student types, in the calculator and
## in every typed answer. A GDScript port of TinyExpr's recursive descent parser.
##
## TinyExpr - Tiny recursive descent parser and evaluation engine in C
## Copyright (c) 2015-2020 Lewis Van Winkle
## http://CodePlea.com
##
## This software is provided 'as-is', without any express or implied
## warranty. In no event will the authors be held liable for any damages
## arising from the use of this software.
##
## Permission is granted to anyone to use this software for any purpose,
## including commercial applications, and to alter it and redistribute it
## freely, subject to the following restrictions:
##
## 1. The origin of this software must not be misrepresented; you must not
##    claim that you wrote the original software. If you use this software
##    in a product, an acknowledgement in the product documentation would be
##    appreciated but is not required.
## 2. Altered source versions must be plainly marked as such, and must not be
##    misrepresented as being the original software.
## 3. This notice may not be removed or altered from any source distribution.
##
## ALTERED SOURCE: this is not the original TinyExpr. It is a port to GDScript, changed
## for Wasteland Academy: the parse builds a tree of plain Arrays and evaluation is a
## separate step; 2x and 2(x + 1) are read as 2 × x and 2 × (x + 1); powers are worked
## right to left like a TI (2^3^2 = 2^9) and bind tighter than a leading minus
## (−3^2 = −9); trig works in degrees or radians; Ans, π and e; log is base 10 and ln
## is natural; a fraction of whole numbers is kept exact (eval_exact) for marking.
##
## Grammar (one function each below):
##   expr    = term {("+" | "−") term}
##   term    = unary {("×" | "÷" | implicit ×) unary}
##   unary   = ("−" | "+") unary | power
##   power   = postfix ["^" unary]          right to left, so 2^-1 and 2^3^2 work
##   postfix = base {"²" | "³"}
##   base    = number | name | "(" expr ")" | function "(" expr ")" | function power
##
## Nothing here calls into the engine: names are looked up in the fixed tables
## FUNCTIONS and CONSTANTS and anything else is an error. Godot's Expression class is
## never used on student input (it reads 2^3 as 1 and can call engine functions).

const FUNCTIONS := ["sin", "cos", "tan", "asin", "acos", "atan", "ln", "log", "sqrt", "abs", "exp"]
## Other spellings a student might type for the same functions.
const ALIASES := {"arcsin": "asin", "arccos": "acos", "arctan": "atan", "sin⁻¹": "asin", "cos⁻¹": "acos",
	"tan⁻¹": "atan", "√": "sqrt", "pi": "π"}
const CONSTANTS := ["π", "e"]
## The longest whole number or decimal it reads, in digits (Q stays inside 64 bits).
const MAX_DIGITS := 15
## Exact work stops (eval_exact gives null) once a numerator or denominator passes this.
const EXACT_LIMIT := 1e15

const ERR_NOT_MATHS := "That isn't something the calculator can work out."


# ── Parsing ──────────────────────────────────────────────────

## Reads `text`. `variables` are the names it may use besides π and e (["x"] for a
## graph, ["ans"] in the calculator). Returns {"ok": true, "tree", "names": [used
## variables], "decimal": bool (a number was typed with a point)} or
## {"ok": false, "error"}.
static func parse(text: String, variables: Array = []) -> Dictionary:
	var lex := _tokens(text, variables)
	if lex.has("error"):
		return {"ok": false, "error": lex.error}
	if lex.tokens.is_empty():
		return {"ok": false, "error": "empty"}
	var p := {"t": lex.tokens, "i": 0, "error": "", "names": [], "decimal": false}
	var tree = _expr(p)
	if p.error == "" and p.i < p.t.size():
		p.error = _unexpected(p.t[p.i])
	if p.error != "":
		return {"ok": false, "error": p.error}
	return {"ok": true, "tree": tree, "names": p.names, "decimal": p.decimal}


## Tokens: ["num", text], ["name", id], ["fn", id], ["op", ch], ["(", ""], [")", ""].
static func _tokens(text: String, variables: Array) -> Dictionary:
	var s := text.strip_edges()
	for pair in [["−", "-"], ["–", "-"], ["—", "-"], ["×", "*"], ["·", "*"], ["÷", "/"], ["＾", "^"],
			["½", "(1/2)"]]:
		s = s.replace(pair[0], pair[1])
	var out: Array = []
	var i := 0
	var n := s.length()
	while i < n:
		var c := s[i]
		if c == " " or c == "\t":
			i += 1
			continue
		if _is_digit(c) or (c == "." and i + 1 < n and _is_digit(s[i + 1])):
			var j := i
			var seen_point := false
			while j < n and (_is_digit(s[j]) or (s[j] == "." and not seen_point)):
				if s[j] == ".":
					seen_point = true
				j += 1
			# Two numbers side by side (2 3, 2.3.4) are a typo, not 2 × 3, and a number
			# straight after a name (x2, 1e3) is unclear: put × between them.
			if not out.is_empty() and (out[-1][0] == "num" or (out[-1][0] == "name" and s[i - 1] != " ")):
				return {"error": "Type one number, or put an operation between them."}
			out.append(["num", s.substr(i, j - i)])
			i = j
			continue
		if c in "+-*/^":
			out.append(["op", c])
			i += 1
			continue
		if c == "²" or c == "³":
			out.append(["sq", "2" if c == "²" else "3"])
			i += 1
			continue
		if c == "(" or c == "[":
			out.append(["(", ""])
			i += 1
			continue
		if c == ")" or c == "]":
			out.append([")", ""])
			i += 1
			continue
		if c == "√":
			out.append(["fn", "sqrt"])
			i += 1
			continue
		if c == "π":
			out.append(["name", "π"])
			i += 1
			continue
		if _is_letter(c):
			var j := i
			while j < n and (_is_letter(s[j]) or (s[j] == "⁻" or s[j] == "¹")):
				j += 1
			var word := s.substr(i, j - i)
			var split := _split_word(word.to_lower(), variables)
			if split.is_empty():
				return {"error": ERR_NOT_MATHS}
			out.append_array(split)
			i = j
			continue
		return {"error": ERR_NOT_MATHS}
	return {"tokens": out}


## A run of letters as known names: "sin", "x", "pix" (π × x), "ex" (e × x), "ans".
## Longest known name first, from the left. [] if any part isn't known.
static func _split_word(word: String, variables: Array) -> Array:
	var out: Array = []
	var known: Array = []
	for f in FUNCTIONS:
		known.append(f)
	for a in ALIASES:
		known.append(a)
	for v in variables:
		known.append(v)
	known.append("e")
	known.sort_custom(func(a, b): return a.length() > b.length())
	var i := 0
	while i < word.length():
		var hit := ""
		for k in known:
			if word.substr(i, k.length()) == k:
				hit = k
				break
		if hit == "":
			return []
		var id: String = ALIASES.get(hit, hit)
		if id in FUNCTIONS:
			out.append(["fn", id])
		else:
			out.append(["name", id])
		i += hit.length()
	return out


static func _is_digit(c: String) -> bool:
	return c >= "0" and c <= "9"


static func _is_letter(c: String) -> bool:
	return (c >= "a" and c <= "z") or (c >= "A" and c <= "Z")


static func _peek(p: Dictionary) -> Array:
	return p.t[p.i] if p.i < p.t.size() else ["end", ""]


static func _unexpected(tok: Array) -> String:
	match tok[0]:
		"end":
			return "It ends too soon."
		")":
			return "There's a ) with no ( before it."
	return "Something is out of place near \"%s\"." % tok[1]


static func _expr(p: Dictionary) -> Variant:
	var left = _term(p)
	while p.error == "":
		var tok := _peek(p)
		if tok[0] == "op" and (tok[1] == "+" or tok[1] == "-"):
			p.i += 1
			var right = _term(p)
			left = ["add" if tok[1] == "+" else "sub", left, right]
		else:
			break
	return left


## Starts a base, so two of them side by side multiply: 2x, 2(x + 1), (x)(x), 3π.
static func _starts_base(tok: Array) -> bool:
	return tok[0] in ["num", "name", "fn", "("]


static func _term(p: Dictionary) -> Variant:
	var left = _unary(p)
	while p.error == "":
		var tok := _peek(p)
		if tok[0] == "op" and (tok[1] == "*" or tok[1] == "/"):
			p.i += 1
			var right = _unary(p)
			left = ["mul" if tok[1] == "*" else "div", left, right]
		elif _starts_base(tok):
			# Implicit ×, at the same level as × (1/2x is x/2, as on a TI-84).
			var right = _power(p)
			left = ["mul", left, right]
		else:
			break
	return left


static func _unary(p: Dictionary) -> Variant:
	var tok := _peek(p)
	if tok[0] == "op" and (tok[1] == "-" or tok[1] == "+"):
		p.i += 1
		var inner = _unary(p)
		return ["neg", inner] if tok[1] == "-" else inner
	return _power(p)


static func _power(p: Dictionary) -> Variant:
	var b = _postfix(p)
	var tok := _peek(p)
	if p.error == "" and tok[0] == "op" and tok[1] == "^":
		p.i += 1
		var e = _unary(p)
		return ["pow", b, e]
	return b


static func _postfix(p: Dictionary) -> Variant:
	var b = _base(p)
	while p.error == "" and _peek(p)[0] == "sq":
		var k: String = _peek(p)[1]
		p.i += 1
		b = ["pow", b, ["num", Q.new(int(k)), float(k)]]
	return b


static func _base(p: Dictionary) -> Variant:
	var tok := _peek(p)
	match tok[0]:
		"num":
			p.i += 1
			var txt: String = tok[1]
			if txt.contains("."):
				p.decimal = true
			var q := _decimal(txt)
			if q == null:
				p.error = "That number has too many digits."
				return null
			return ["num", q, txt.to_float()]
		"name":
			p.i += 1
			var id: String = tok[1]
			if id in CONSTANTS:
				return ["const", id]
			if not id in p.names:
				p.names.append(id)
			return ["var", id]
		"fn":
			p.i += 1
			var arg
			if _peek(p)[0] == "(":
				# sin(30)^2 is (sin 30)^2, as on a TI: the brackets are the argument.
				p.i += 1
				arg = _expr(p)
				if p.error == "" and _peek(p)[0] != ")":
					p.error = "A bracket is missing a )."
				p.i += 1
			else:
				# sin 30 and √2: the argument is the next power (sin x² is sin(x²)).
				if _peek(p)[0] == "end":
					p.error = "%s needs something after it." % tok[1]
					return null
				arg = _power(p)
			return ["fn", tok[1], arg]
		"(":
			p.i += 1
			var inner = _expr(p)
			if p.error == "" and _peek(p)[0] != ")":
				p.error = "A bracket is missing a )."
			p.i += 1
			return inner
	p.error = _unexpected(tok)
	return null


## A typed whole number or decimal as an exact Q, or null with more than MAX_DIGITS.
static func _decimal(s: String) -> Q:
	var parts := s.split(".")
	var whole := parts[0]
	var frac := parts[1] if parts.size() > 1 else ""
	var digits := (whole + frac).lstrip("0")
	if digits.length() > MAX_DIGITS:
		return null
	var den := 1
	for i in frac.length():
		den *= 10
		if den > 1000000000000000:
			return null
	return Q.new((whole + frac).to_int(), den)


# ── Evaluation ───────────────────────────────────────────────

## The value of a parsed tree as a float. env: variable name -> float ("x", "ans"),
## and "deg": true to work trig in degrees. A name with no value gives NAN.
static func eval_float(tree: Variant, env: Dictionary = {}) -> float:
	match tree[0]:
		"num":
			return tree[2]
		"const":
			return PI if tree[1] == "π" else exp(1.0)
		"var":
			return float(env.get(tree[1], NAN))
		"neg":
			return -eval_float(tree[1], env)
		"add":
			return eval_float(tree[1], env) + eval_float(tree[2], env)
		"sub":
			return eval_float(tree[1], env) - eval_float(tree[2], env)
		"mul":
			return eval_float(tree[1], env) * eval_float(tree[2], env)
		"div":
			var b := eval_float(tree[2], env)
			return NAN if b == 0.0 else eval_float(tree[1], env) / b
		"pow":
			return _pow(eval_float(tree[1], env), eval_float(tree[2], env))
		"fn":
			return _call(tree[1], eval_float(tree[2], env), env.get("deg", false))
	return NAN


## Real powers: a negative base to a whole power, or to 1/odd (∛−8 = −2).
static func _pow(a: float, b: float) -> float:
	if a < 0.0 and b != floorf(b):
		var inv := 1.0 / b
		if absf(inv - roundf(inv)) < 1e-9 and int(roundf(inv)) % 2 != 0:
			return -pow(-a, b)
		return NAN
	if a == 0.0 and b < 0.0:
		return NAN
	return pow(a, b)


static func _call(f: String, v: float, deg: bool) -> float:
	var k := PI / 180.0 if deg else 1.0
	match f:
		"sin":
			return _snap(sin(v * k))
		"cos":
			return _snap(cos(v * k))
		"tan":
			var c := cos(v * k)
			return NAN if absf(c) < 1e-15 else _snap(tan(v * k))
		"asin":
			return asin(v) / k if absf(v) <= 1.0 else NAN
		"acos":
			return acos(v) / k if absf(v) <= 1.0 else NAN
		"atan":
			return atan(v) / k
		"ln":
			return log(v) if v > 0.0 else NAN
		"log":
			return log(v) / log(10.0) if v > 0.0 else NAN
		"sqrt":
			return sqrt(v) if v >= 0.0 else NAN
		"abs":
			return absf(v)
		"exp":
			return exp(v)
	return NAN


## Trig of a whole number of degrees lands on rounding dust (sin 30° = 0.49999999999999994):
## snap values within 1e-15 of a nice one, so sin(30) shows 0.5 and tan(45) shows 1.
static func _snap(v: float) -> float:
	for nice in [0.0, 0.5, -0.5, 1.0, -1.0]:
		if absf(v - nice) < 1e-15:
			return nice
	return v


## The exact value of a tree as a Q when it is a fraction of whole numbers: + − × ÷,
## whole powers and square roots of perfect squares. null for anything irrational (π,
## √2, ln 2), a variable, or a fraction too big for 64 bits.
static func eval_exact(tree: Variant) -> Q:
	match tree[0]:
		"num":
			return tree[1]
		"neg":
			var a := eval_exact(tree[1])
			return a.neg() if a != null else null
		"add", "sub", "mul", "div":
			var a := eval_exact(tree[1])
			var b := eval_exact(tree[2])
			if a == null or b == null:
				return null
			if tree[0] == "div" and b.is_zero():
				return null
			# Check the size first, so Q's 64-bit work can't overflow.
			var big := float(maxi(absi(a.n), a.d)) * float(maxi(absi(b.n), b.d))
			if big > EXACT_LIMIT:
				return null
			match tree[0]:
				"add":
					return a.add(b)
				"sub":
					return a.sub(b)
				"mul":
					return a.mul(b)
			return a.div(b)
		"pow":
			var a := eval_exact(tree[1])
			var b := eval_exact(tree[2])
			if a == null or b == null or not b.is_int() or absi(b.n) > 64:
				return null
			if b.n < 0 and a.is_zero():
				return null
			var size := pow(float(maxi(absi(a.n), a.d)), float(absi(b.n)))
			if size > EXACT_LIMIT:
				return null
			var out := Q.new(1)
			for i in absi(b.n):
				out = out.mul(a)
			return out if b.n >= 0 else Q.new(1).div(out)
		"fn":
			if tree[1] == "sqrt":
				var a := eval_exact(tree[2])
				if a == null or a.n < 0:
					return null
				var rn := roundi(sqrt(float(a.n)))
				var rd := roundi(sqrt(float(a.d)))
				if rn * rn == a.n and rd * rd == a.d:
					return Q.new(rn, rd)
			elif tree[1] == "abs":
				var a := eval_exact(tree[2])
				return a.abs_q() if a != null else null
	return null


## Parses and works out `text` in one step. env as for eval_float; its keys are the
## variables it may use. Returns {"ok": true, "value": float, "exact": Q or null} or
## {"ok": false, "error"}.
static func evaluate(text: String, env: Dictionary = {}) -> Dictionary:
	var names: Array = env.keys().filter(func(k): return k != "deg")
	var r := parse(text, names)
	if not r.ok:
		return r
	var v := eval_float(r.tree, env)
	if not is_finite(v):
		return {"ok": false, "error": "That has no real value."}
	return {"ok": true, "value": v, "exact": eval_exact(r.tree)}
