class_name MathText
extends RefCounted
## Cuts a line of maths into what MathLabel lays out (FAL-797): plain text, powers written
## with a caret (as Fmt.power_runs) and fractions written with a slash, which it stacks
## over a bar as on paper. The questions keep their slashes and carets:
## tools/check_answers.py parses them, and a typed answer can still use /.
##
## parse() gives an Array of nodes: a String is plain text, {"pow": nodes} is a power and
## {"num": nodes, "den": nodes} a fraction. A fraction takes, on each side of its slash:
##   - a whole term: "2πx", "x²", "e^(2x)", "f(x)", "n!", "√3", or a bracket, whose
##     brackets go, as on paper ("(x + 1)/(x − 1)"). A sign in front stays in front:
##     −3/4 is −(3/4), and the minus is drawn before the bar.
##   - a function and its argument: "sin 4x/cos 4x", "ln b / ln a", "log₂ a/log₂ 16".
##   - after a number, a bracket is a factor, not part of the bottom: π/4(t − 4) is
##     (π/4)(t − 4), and n/2(u₁ + uₙ) is (n/2)(u₁ + uₙ), as the questions mean them.
##   - fractions in a chain go from the left: 1/4/3 is (1/4)/3.
## A bracket round just a fraction goes too, unless it's needed: (3/2)x is drawn as a
## stacked 3/2 then x, and (1/3)(x − 1) as 1/3 then (x − 1), but (2/3)⁵, ln(3/2),
## 2(1/2) and (−1/2) keep theirs.
## A slash is left as written when it has a space on one side only, or when it is a
## unit (m/s, km/h), a calculator setting (P/Y) or a pair of words ("zero/root").

const FUNCS := ["sin", "cos", "tan", "sec", "csc", "cot", "arcsin", "arccos", "arctan", "ln", "log", "exp"]
const UNIT_TOPS := ["m", "km", "cm", "mm", "rad", "mg", "kg", "g", "P", "C"]
const UNIT_BOTTOMS := ["s", "s²", "h", "l", "Y", "min"]
## Characters that belong to a term with the letters and digits round them.
const MARKS := "₀₁₂₃₄₅₆₇₈₉ₙ₊₋ₑᵢₐₓₖ⁰¹²³⁴⁵⁶⁷⁸⁹⁻ⁿ′″!°∞_"
## What can follow a bracket and bind to it: (2/3)⁵, (x + 1)!.
const POSTFIX := "⁰¹²³⁴⁵⁶⁷⁸⁹⁻ⁿ′″!"


## True if s has a fraction or a power to draw, so a plain Label won't do.
static func has_markup(s: String) -> bool:
	if not s.contains("/") and not s.contains("^"):
		return false
	return parse(s).any(func(n): return n is Dictionary)


static func parse(s: String) -> Array:
	return _build(s, _fractions(s), 0, s.length())


## The text as one line, with the carets gone and the slashes kept: "e^(2x) + 1/2" is
## "e2x + 1/2". A top or bottom with a space in it gets its brackets back.
static func plain(nodes: Array) -> String:
	var out := ""
	for n in nodes:
		if n is String:
			out += n
		elif n.has("pow"):
			out += plain(n.pow)
		else:
			out += _bracketed(plain(n.num)) + "/" + _bracketed(plain(n.den))
	return out


static func _bracketed(s: String) -> String:
	return "(%s)" % s if s.contains(" ") else s


## Every fraction in s, left to right, as {top, top_end, bottom, end}: the top is
## s[top, top_end) and the bottom s[bottom, end).
static func _fractions(s: String) -> Array:
	var out := []
	var n := s.length()
	for i in n:
		if s[i] != "/":
			continue
		var left_space := i > 0 and s[i - 1] == " "
		var right_space := i + 1 < n and s[i + 1] == " "
		if left_space != right_space:
			continue
		var top_end := i - 1 if left_space else i
		var bottom := i + 2 if right_space else i + 1
		var top := _top_start(s, top_end)
		var end := _bottom_end(s, bottom)
		if top == top_end or end == bottom:
			continue
		var a := s.substr(top, top_end - top)
		var b := s.substr(bottom, end - bottom)
		if (_word(a) and _word(b) and a.length() >= 3 and b.length() >= 3) \
				or ((a in UNIT_TOPS or a.ends_with("°")) and b in UNIT_BOTTOMS):
			continue
		top = _with_function(s, top)
		# A chain: the fraction before ends where this top does, so it is this top.
		for f in out:
			if f.end == top_end and f.top < top:
				top = f.top
		out.append({"top": top, "top_end": top_end, "bottom": bottom, "end": end})
	return out


## The nodes for s[from, to).
static func _build(s: String, fracs: Array, from: int, to: int) -> Array:
	var out := []
	var text := ""
	var i := from
	while i < to:
		var f := _fraction_at(fracs, i, to)
		var close := _close(s, i) if s[i] == "(" else -1
		# A bracket round just a fraction, which it doesn't need.
		if f.is_empty() and close > 0 and close < to and _bare(s, i, close):
			f = _fraction_at(fracs, i + 1, close)
			if not f.is_empty() and f.end == close:
				_flush(out, text)
				text = ""
				out.append(_fraction(s, fracs, f))
				i = close + 1
				continue
			f = {}
		if not f.is_empty():
			_flush(out, text)
			text = ""
			out.append(_fraction(s, fracs, f))
			i = f.end
			continue
		var p := Fmt._power_end(s, i + 1) if s[i] == "^" else 0
		if p > i + 1 and p <= to:
			_flush(out, text)
			text = ""
			var bracketed := s[i + 1] == "("
			out.append({"pow": _build(s, fracs, i + 2, p - 1) if bracketed else _build(s, fracs, i + 1, p)})
			i = p
			continue
		text += s[i]
		i += 1
	_flush(out, text)
	return out


static func _flush(out: Array, text: String) -> void:
	if text != "":
		out.append(text)


static func _fraction(s: String, fracs: Array, f: Dictionary) -> Dictionary:
	return {"num": _operand(s, fracs, f.top, f.top_end), "den": _operand(s, fracs, f.bottom, f.end)}


## A fraction's top or bottom, without the brackets round all of it.
static func _operand(s: String, fracs: Array, from: int, to: int) -> Array:
	if s[from] == "(" and _close(s, from) == to - 1:
		return _build(s, fracs, from + 1, to - 1)
	return _build(s, fracs, from, to)


## The widest fraction that starts at i and ends by to, or {}.
static func _fraction_at(fracs: Array, i: int, to: int) -> Dictionary:
	var best := {}
	for f in fracs:
		if f.top == i and f.end <= to and (best.is_empty() or f.end > best.end):
			best = f
	return best


## True if the bracket s[open..close] can go: nothing before it that it belongs to (a
## function, a number it multiplies) and nothing after it that binds to it (a power).
static func _bare(s: String, open: int, close: int) -> bool:
	if open > 0:
		var c := s[open - 1]
		if _term(c) or c == ")" or c == "√" or c == "∛" or c == "^":
			return false
	if close + 1 < s.length():
		var c := s[close + 1]
		if POSTFIX.contains(c) or c == "^" or c.is_valid_int():
			return false
	return true


## Where the top that ends at at starts: back over a term, its powers and brackets.
static func _top_start(s: String, at: int) -> int:
	var j := at
	while j > 0:
		var c := s[j - 1]
		if c == ")":
			var o := _open(s, j - 1)
			if o < 0:
				break
			j = o
		elif c == "." and j >= 2 and s[j - 2].is_valid_int() and j < s.length() and s[j].is_valid_int():
			j -= 1
		elif c in ["−", "-"] and j >= 2 and s[j - 2] == "^":
			j -= 2
		elif c == "^" or c == "√" or c == "∛" or _term(c):
			j -= 1
		else:
			break
	return j


## Where the bottom that starts at at ends, or at if there isn't one.
static func _bottom_end(s: String, at: int) -> int:
	var n := s.length()
	var j := at
	if j < n and s[j] in ["−", "-"]:
		j += 1
	while j < n and (s[j] == "√" or s[j] == "∛"):
		j += 1
	if j >= n:
		return at
	if s[j] == "(":
		var close := _close(s, j)
		return _postfix(s, close + 1) if close > 0 else at
	var start := j
	while j < n:
		var c := s[j]
		if c == "." and j > start and s[j - 1].is_valid_int() and j + 1 < n and s[j + 1].is_valid_int():
			j += 1
		elif c == "^":
			var p := Fmt._power_end(s, j + 1)
			if p <= j + 1:
				break
			j = p
		elif c == "(" and j > start and (_letter(s[j - 1]) or "′″".contains(s[j - 1])):
			# A function's bracket: 1/f(1), 1/ln(1.25).
			var close := _close(s, j)
			if close < 0:
				break
			j = _postfix(s, close + 1)
		elif _term(c):
			j += 1
		else:
			break
	if j == start:
		return at
	# A function and its argument after a space: cos 4x, ln 0.81, log₂ 16.
	if _is_function(s.substr(start, j - start)) and j + 1 < n and s[j] == " " and _term(s[j + 1]):
		j += 1
		while j < n and (_term(s[j]) or (s[j] == "." and s[j - 1].is_valid_int() and j + 1 < n and s[j + 1].is_valid_int())):
			j += 1
	return j


## top moved back over a function written before it with a space: "sin 4x", "log₂ a".
static func _with_function(s: String, top: int) -> int:
	if top < 2 or s[top - 1] != " ":
		return top
	var j := top - 1
	while j > 0 and (_letter(s[j - 1]) or MARKS.contains(s[j - 1]) or s[j - 1].is_valid_int()):
		j -= 1
	return j if _is_function(s.substr(j, top - 1 - j)) else top


## True for sin, cos²θ's "cos²", log₂, log_c and the like.
static func _is_function(w: String) -> bool:
	var head := ""
	for c in w:
		if not _letter(c):
			break
		head += c
	if not head in FUNCS:
		return false
	for c in w.substr(head.length()):
		if not MARKS.contains(c) and not c.is_valid_int() and not _letter(c):
			return false
	return true


static func _postfix(s: String, j: int) -> int:
	while j < s.length():
		if POSTFIX.contains(s[j]):
			j += 1
		elif s[j] == "^" and Fmt._power_end(s, j + 1) > j + 1:
			j = Fmt._power_end(s, j + 1)
		else:
			break
	return j


static func _close(s: String, open: int) -> int:
	var depth := 0
	for j in range(open, s.length()):
		depth += int(s[j] == "(") - int(s[j] == ")")
		if depth == 0:
			return j
	return -1


static func _open(s: String, close: int) -> int:
	var depth := 0
	for j in range(close, -1, -1):
		depth += int(s[j] == ")") - int(s[j] == "(")
		if depth == 0:
			return j
	return -1


static func _letter(c: String) -> bool:
	return c.to_lower() != c.to_upper()


static func _term(c: String) -> bool:
	return c.is_valid_int() or _letter(c) or MARKS.contains(c)


## True if w is all letters.
static func _word(w: String) -> bool:
	for c in w:
		if not _letter(c):
			return false
	return w != ""
