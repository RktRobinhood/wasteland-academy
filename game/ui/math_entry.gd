class_name MathEntry
extends Control
## An answer box typed in maths notation (FAL-812), as on a TI-84 Plus CE in MathPrint
## mode: the fraction key stacks a fraction you type into, an empty part shows a dashed
## box, and ◀ ▶ move the cursor through it. It draws a MathBox tree (FAL-797), so a typed
## fraction looks like a shown one.
##
## It stands in for the LineEdit the answer slots were: `text` gives the tree back in the
## syntax Answer.parse_number reads, a fraction as (n)/(d), and setting `text` builds the
## same tree, so code that sets "3/2" sees a stacked fraction. It grows as it's typed in,
## is styled as a LineEdit (UiTheme declares MathEntry as a LineEdit variation), and
## Enter emits text_submitted.
##
## The calculator (FAL-813) types into one too: ^ makes a raised power to type into and √
## a root with a bar over what is in it, each given back as ^(…) and √(…), the syntax
## Expr reads. ▶ (or a ")" with no bracket open) leaves them.
##
##   var e := MathEntry.new()
##   e.press("3"); e.press(MathEntry.FRACTION); e.press("4")   # e.text == "(3)/(4)"
##   e.press("2"); e.press(MathEntry.POWER); e.press("5")      # e.text == "2^(5)"

signal text_submitted(text: String)
signal text_changed(text: String)

## The key that makes a fraction (Keypad's "/" key), a power and a root, and the cursor keys.
const FRACTION := "/"
const POWER := "^"
const ROOT := "√"
const LEFT := "◀"
const RIGHT := "▶"
## What a number just before the cursor is made of: the fraction key makes it the top.
const NUMBER := "0123456789."
## The boxes with rows to type into.
const HOLDERS := [MathBox.Kind.FRACTION, MathBox.Kind.POWER, MathBox.Kind.ROOT, MathBox.Kind.SUB]
## Shown as typed: a true minus and times sign. text gives them back as - and *.
const SHOWN := {"-": "−", "*": "×"}
## The caret's width, and the dashes of an empty part's box, as a share of the size.
const CARET := 3.0
const DASH := 0.1
## An empty part's dashed box: a digit's width, from the baseline to this share of the
## size, about a digit's height.
const EMPTY_TOP := 0.74
## Room for the caret past the end of the maths.
const END_ROOM := 8.0

## The most that can be typed: characters, and one for each fraction. 0 for no limit.
var max_length := 0
var editable := true:
	set(v):
		editable = v
		queue_redraw()
## Where the maths sits across the box: centred for an answer, left for the calculator.
var alignment := HORIZONTAL_ALIGNMENT_CENTER:
	set(v):
		alignment = v
		queue_redraw()
## Shown in an empty box.
var placeholder_text := "?":
	set(v):
		placeholder_text = v
		_changed(false)
## The answer as Answer.parse_number reads it.
var text: String:
	get:
		return _plain(root)
	set(v):
		_set_text(v)

## The tree: a ROW of TEXT boxes (one character, or a key's name such as "sin(") and
## FRACTION, POWER and ROOT boxes, whose rows are the same.
var root := MathBox.row()
## The cursor: before the box at this index in this row.
var row := root
var at := 0

## Set by _layout(): where the maths' baseline starts, and each row's cursor places.
var _origin := Vector2.ZERO
## Each row: {"row", "xs" (the cursor's x at each index), "y" (the baseline), "size"}.
var _places: Array = []
## Each empty part: {"row", "rect" (its dashed box)}.
var _empty: Array = []
var _content := Vector2.ZERO


func _init() -> void:
	theme_type_variation = &"MathEntry"
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_IBEAM


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_THEME_CHANGED, NOTIFICATION_ENTER_TREE:
			_changed(false)
		NOTIFICATION_FOCUS_ENTER, NOTIFICATION_FOCUS_EXIT:
			queue_redraw()


# ── Keys ─────────────────────────────────────────────────────

## A key from the keypad, or a character typed: Del, the fraction, power and root keys,
## ◀ ▶, a closing bracket, or text.
func press(k: String) -> void:
	if not editable:
		return
	match k:
		"Del":
			backspace()
		FRACTION:
			fraction()
		POWER:
			power()
		ROOT:
			root_box()
		")":
			close_bracket()
		LEFT:
			move_left()
		RIGHT:
			move_right()
		_:
			for c in k:
				insert(c)


## One box of text at the cursor: a character, or a key's name ("sin(", "Ans"), which
## Del then takes away whole, as on the TI.
func insert(c: String) -> void:
	if _full():
		return
	row.children.insert(at, MathBox.text_box(SHOWN.get(c, c)))
	at += 1
	_changed()


## Text in the syntax `text` gives, typed in at the cursor: "(1)/(3)" goes in as a fraction.
func paste(s: String) -> void:
	var budget := [max_length - _count(root) if max_length > 0 else 1 << 30]
	for b in _read(s, budget):
		row.children.insert(at, b)
		at += 1
	_changed()


## What is just before the cursor becomes the top and the cursor goes to the bottom: a
## number, a name (Ans, π), a bracket with its function (sin(30)), a fraction, a root or a
## power with its base. Otherwise the fraction starts empty, with the cursor in the top.
func fraction() -> void:
	if _full():
		return
	var start := _operand_start(row.children, at)
	var top := MathBox.row(row.children.slice(start, at))
	var f := MathBox.fraction(top, MathBox.row())
	for i in at - start:
		row.children.remove_at(start)
	row.children.insert(start, f)
	if top.children.is_empty():
		_put(top, 0)
	else:
		_put(f.children[1], 0)
	_changed()


## A raised power, empty, with the cursor in it. What is before the cursor is its base.
func power() -> void:
	_add_holder(MathBox.power(MathBox.row()))


## A root, empty, with the cursor under its bar.
func root_box() -> void:
	_add_holder(MathBox.root(MathBox.row()))


func _add_holder(b: MathBox) -> void:
	if _full():
		return
	row.children.insert(at, b)
	_put(b.children[0], 0)
	_changed()


## ")": at the end of a power or a root with no bracket open in it, the cursor leaves it,
## so √ 2 ) reads √(2) as it would on one line. Anywhere else it is typed.
func close_bracket() -> void:
	var up := _owner(row)
	if not up.is_empty() and up.box.kind != MathBox.Kind.FRACTION and at == row.children.size() \
			and _open_brackets(row) <= 0:
		_put(up.row, up.index + 1)
		queue_redraw()
		return
	insert(")")


## ▶: through the top, then the bottom, then out; into a power or a root, then out.
func move_right() -> void:
	if at < row.children.size():
		var b: MathBox = row.children[at]
		if _is_text(b):
			at += 1
		else:
			_put(b.children[0], 0)
	else:
		var up := _owner(row)
		if up.is_empty():
			return
		var i: int = up.box.children.find(row)
		if i + 1 < up.box.children.size():
			_put(up.box.children[i + 1], 0)
		else:
			_put(up.row, up.index + 1)
	queue_redraw()


## ◀: the other way, into a box at the end of its last row.
func move_left() -> void:
	if at > 0:
		var b: MathBox = row.children[at - 1]
		if _is_text(b):
			at -= 1
		else:
			var last: MathBox = b.children.back()
			_put(last, last.children.size())
	else:
		var up := _owner(row)
		if up.is_empty():
			return
		var i: int = up.box.children.find(row)
		if i > 0:
			var before: MathBox = up.box.children[i - 1]
			_put(before, before.children.size())
		else:
			_put(up.row, up.index)
	queue_redraw()


## ↑ from a bottom to its top, ↓ from a top to its bottom, from the nearest fraction
## that has one.
func move_vertical(down: bool) -> void:
	var r := row
	while true:
		var up := _owner(r)
		if up.is_empty():
			return
		if up.box.kind == MathBox.Kind.FRACTION:
			var from: MathBox = up.box.children[0 if down else 1]
			if r == from:
				var to: MathBox = up.box.children[1 if down else 0]
				_put(to, mini(at if r == row else to.children.size(), to.children.size()))
				queue_redraw()
				return
		r = up.row


## Del: the box before the cursor goes. At the start of an empty bottom, the fraction
## goes and its top stays; at the start of an empty fraction, the fraction goes; at the
## start of a power or a root, it goes and what is in it stays. Before a box, or at the
## start of a part with something in it, the cursor moves back into it.
func backspace() -> void:
	if at > 0:
		var b: MathBox = row.children[at - 1]
		if _is_text(b) or _count(b) == 1:
			row.children.remove_at(at - 1)
			at -= 1
			_changed()
		else:
			move_left()
		return
	var up := _owner(row)
	if up.is_empty():
		return
	var f: MathBox = up.box
	if f.kind != MathBox.Kind.FRACTION:
		_unwrap(up, row)
		return
	var top: MathBox = f.children[0]
	var bottom: MathBox = f.children[1]
	if row == bottom and bottom.children.is_empty():
		_unwrap(up, top)
	elif top.children.is_empty() and bottom.children.is_empty():
		up.row.children.remove_at(up.index)
		_put(up.row, up.index)
		_changed()
	else:
		move_left()


## The box goes and the boxes in keep take its place; the cursor goes after them for a
## fraction's top and before them for a power or a root, where it was.
func _unwrap(up: Dictionary, keep: MathBox) -> void:
	up.row.children.remove_at(up.index)
	for i in keep.children.size():
		up.row.children.insert(up.index + i, keep.children[i])
	_put(up.row, up.index + (keep.children.size() if up.box.kind == MathBox.Kind.FRACTION else 0))
	_changed()


func clear() -> void:
	root = MathBox.row()
	_put(root, 0)
	_changed()


func _gui_input(e: InputEvent) -> void:
	if not editable:
		return
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		grab_focus()
		tap_at(e.position)
		accept_event()
		return
	if not (e is InputEventKey and e.pressed):
		return
	var handled := true
	match e.keycode:
		KEY_ENTER, KEY_KP_ENTER:
			text_submitted.emit(text)
		KEY_LEFT:
			move_left()
		KEY_RIGHT:
			move_right()
		KEY_UP:
			move_vertical(false)
		KEY_DOWN:
			move_vertical(true)
		KEY_BACKSPACE:
			backspace()
		_:
			handled = e.unicode >= 32 and not e.ctrl_pressed and not e.meta_pressed
			if handled:
				press(String.chr(e.unicode))
	if handled:
		accept_event()


## A tap at pos, in the box's own coordinates, puts the cursor at the nearest place in
## the part under it.
func tap_at(pos: Vector2) -> void:
	var best := INF
	for p in _places:
		var s: float = p.size
		var top: float = p.y - s * MathBox.INK_ASCENT
		var bottom: float = p.y + s * MathBox.INK_DESCENT
		var off_y := maxf(0.0, maxf(top - pos.y, pos.y - bottom))
		for i in p.xs.size():
			var d: float = absf(pos.x - p.xs[i]) + off_y * 10.0
			if d < best:
				best = d
				_put(p.row, i)
	queue_redraw()


# ── The tree ─────────────────────────────────────────────────

## Builds the tree from text as Answer.parse_number and Expr read it: a/b, (a)/(b), −3/4,
## 3/−4, 1/2/3, 2^(1/2), e^-x, √(2). What is round a slash's number becomes the fraction,
## what follows a caret the power and what is in √( ) the root; the rest is text.
func _set_text(v: String) -> void:
	var budget := [max_length if max_length > 0 else 1 << 30]
	root = MathBox.row(_read(v, budget))
	_put(root, root.children.size())
	_changed()


func _read(s: String, budget: Array) -> Array:
	var out: Array = []
	var i := 0
	while i < s.length() and budget[0] > 0:
		var c := s[i]
		if c == "/":
			budget[0] -= 1
			var top := _take_left(out)
			var bottom_text := _right_operand(s, i + 1)
			i += 1 + bottom_text.length()
			if bottom_text.begins_with("(") and bottom_text.ends_with(")"):
				bottom_text = bottom_text.substr(1, bottom_text.length() - 2)
			out.append(MathBox.fraction(MathBox.row(top), MathBox.row(_read(bottom_text, budget))))
			continue
		if c == "^":
			budget[0] -= 1
			var inner := _right_operand(s, i + 1)
			i += 1 + inner.length()
			if inner.begins_with("(") and inner.ends_with(")"):
				inner = inner.substr(1, inner.length() - 2)
			out.append(MathBox.power(MathBox.row(_read(inner, budget))))
			continue
		if c == "√" and i + 1 < s.length() and s[i + 1] == "(":
			var shut := _closing(s, i + 1)
			if shut > 0:
				budget[0] -= 1
				out.append(MathBox.root(MathBox.row(_read(s.substr(i + 2, shut - i - 2), budget))))
				i = shut + 1
				continue
		if c == "(":
			var close := _closing(s, i)
			# A bracket round a whole top is the fraction's, not the answer's: (3)/(4).
			if close > 0 and close + 1 < s.length() and s[close + 1] == "/":
				var group := MathBox.row(_read(s.substr(i + 1, close - i - 1), budget))
				group.set_meta("group", true)
				out.append(group)
				i = close + 1
				continue
		budget[0] -= 1
		out.append(MathBox.text_box(SHOWN.get(c, c)))
		i += 1
	# A bracket group that didn't end up on top of a fraction is written out again.
	var flat: Array = []
	for b in out:
		if b.kind == MathBox.Kind.ROW:
			flat.append(MathBox.text_box("("))
			flat.append_array(b.children)
			flat.append(MathBox.text_box(")"))
		else:
			flat.append(b)
	return flat


## The fraction's top, taken off the end of out: what _operand_start() finds, or a
## bracket group just before it.
func _take_left(out: Array) -> Array:
	if not out.is_empty() and out.back().kind == MathBox.Kind.ROW:
		return out.pop_back().children
	var start := _operand_start(out, out.size())
	var top := out.slice(start)
	out.resize(start)
	return top


## Where the operand that ends at items[end] starts: a run of digits, a run of names (Ans,
## π, x), a bracket with the name before it (sin(30)), a fraction, a root, or a power with
## its base. end itself when there is none, as after a + sign.
static func _operand_start(items: Array, end: int) -> int:
	if end <= 0:
		return end
	var b: MathBox = items[end - 1]
	match b.kind:
		MathBox.Kind.ROW, MathBox.Kind.FRACTION, MathBox.Kind.ROOT:
			return end - 1
		MathBox.Kind.POWER, MathBox.Kind.SUB:
			return _operand_start(items, end - 1)
	if b.text == ")":
		var depth := 0
		for j in range(end - 1, -1, -1):
			var t: MathBox = items[j]
			if not _is_text(t):
				continue
			if t.text == ")":
				depth += 1
			elif t.text.ends_with("("):
				depth -= 1
				if depth == 0:
					var k := j
					while t.text == "(" and k > 0 and _is_text(items[k - 1]) and _is_name(items[k - 1].text):
						k -= 1
					return k
		return end
	var digits := _all_in(b.text, NUMBER)
	if not digits and not _is_name(b.text):
		return end
	var start := end
	while start > 0 and _is_text(items[start - 1]) and (_all_in(items[start - 1].text, NUMBER) if digits else _is_name(items[start - 1].text)):
		start -= 1
	return start


static func _all_in(t: String, chars: String) -> bool:
	for c in t:
		if not c in chars:
			return false
	return t != ""


## Letters only: Ans, π, e, x, or a function's name typed letter by letter.
static func _is_name(t: String) -> bool:
	for c in t:
		if c.to_lower() == c.to_upper():
			return false
	return t != ""


## The text of the fraction's bottom, from s at i: a bracket group, or a sign and a run
## of digits (or letters).
func _right_operand(s: String, i: int) -> String:
	if i >= s.length():
		return ""
	if s[i] == "(":
		var close := _closing(s, i)
		if close > 0:
			return s.substr(i, close - i + 1)
	var j := i
	if s[j] in "-−":
		j += 1
	var digits := j < s.length() and s[j] in NUMBER
	while j < s.length() and _operand_char(s[j], digits):
		j += 1
	return s.substr(i, j - i)


static func _operand_char(c: String, digits: bool) -> bool:
	if digits:
		return c in NUMBER
	return c.to_lower() != c.to_upper()


static func _closing(s: String, open: int) -> int:
	var depth := 0
	for j in range(open, s.length()):
		if s[j] == "(":
			depth += 1
		elif s[j] == ")":
			depth -= 1
			if depth == 0:
				return j
	return -1


static func _is_text(b: MathBox) -> bool:
	return b.kind == MathBox.Kind.TEXT


static func _is_holder(b: MathBox) -> bool:
	return b.kind in HOLDERS


## What has been typed in b: its characters (a key's name is one), and one for each
## fraction, power and root.
static func _count(b: MathBox) -> int:
	if _is_text(b):
		return 1
	var n := 1 if _is_holder(b) else 0
	for c in b.children:
		n += _count(c)
	return n


static func _plain(b: MathBox) -> String:
	var s := b.to_text()
	for k in SHOWN:
		s = s.replace(SHOWN[k], k)
	return s


## The box a row is a part of (a fraction's top or bottom, a power's or a root's row),
## as {"box", "row" (the row that holds it), "index" (its place there)}. {} for the top row.
func _owner(r: MathBox) -> Dictionary:
	return _find_owner(root, r)


static func _find_owner(holder: MathBox, r: MathBox) -> Dictionary:
	for i in holder.children.size():
		var f: MathBox = holder.children[i]
		if not _is_holder(f):
			continue
		for part in f.children:
			if part == r:
				return {"box": f, "row": holder, "index": i}
			var deeper := _find_owner(part, r)
			if not deeper.is_empty():
				return deeper
	return {}


func _full() -> bool:
	return max_length > 0 and _count(root) >= max_length


## Brackets opened before the cursor in its row and not yet closed there.
func _open_brackets(r: MathBox) -> int:
	var n := 0
	for i in at:
		var b: MathBox = r.children[i]
		if _is_text(b):
			if b.text.ends_with("("):
				n += 1
			elif b.text == ")":
				n -= 1
	return n


## A copy of the tree, for showing what was typed after the box is cleared.
func tree() -> MathBox:
	return _copy(root)


static func _copy(b: MathBox) -> MathBox:
	var c := MathBox.new()
	c.kind = b.kind
	c.text = b.text
	c.children = b.children.map(_copy)
	return c


func _put(r: MathBox, i: int) -> void:
	row = r
	at = clampi(i, 0, r.children.size())


func _changed(emit := true) -> void:
	_layout()
	update_minimum_size()
	queue_redraw()
	if emit:
		text_changed.emit(text)


# ── Layout and drawing ───────────────────────────────────────

## The LineEdit's look, asked for by name, so it holds in a theme that doesn't declare
## the variation.
func _font() -> Font:
	return get_theme_font("font", "LineEdit")


func _size() -> int:
	return get_theme_font_size("font_size", "LineEdit")


func _style(state: String) -> StyleBox:
	return get_theme_stylebox(state, "LineEdit")


## Lays the tree out with each empty part holding a stand-in the size of a digit, so it
## keeps its place, then lists the cursor places and the empty parts' boxes. The
## stand-ins come out again before drawing; the boxes keep where they were laid out.
func _layout() -> void:
	var font := _font()
	if font == null:
		return
	var s := _size()
	var stand_ins: Array = []
	_fill_empty(root, stand_ins)
	root.layout(font, s)
	var asc := maxf(font.get_ascent(s), root.asc)
	var desc := maxf(font.get_descent(s), root.desc)
	_content = Vector2(root.w, asc + desc)
	if root.children.is_empty():
		_content.x = font.get_string_size(placeholder_text, HORIZONTAL_ALIGNMENT_LEFT, -1, s).x
	_origin = Vector2(0.0, asc)
	_places.clear()
	_empty.clear()
	_collect(root, Vector2.ZERO, stand_ins)
	for b in stand_ins:
		for r in _parts(root):
			r.children.erase(b)


func _fill_empty(b: MathBox, stand_ins: Array) -> void:
	for f in b.children:
		if _is_holder(f):
			for part in f.children:
				if part.children.is_empty():
					var s := MathBox.text_box("0")
					part.children.append(s)
					stand_ins.append(s)
				else:
					_fill_empty(part, stand_ins)


func _parts(b: MathBox) -> Array:
	var out := [b]
	for f in b.children:
		if _is_holder(f):
			for part in f.children:
				out.append_array(_parts(part))
	return out


## Cursor places for r, laid out at origin (relative to _origin), and the same for the
## parts of its fractions, powers and roots.
func _collect(r: MathBox, origin: Vector2, stand_ins: Array) -> void:
	var xs: Array = []
	var real := r.children.filter(func(b): return not b in stand_ins)
	if real.is_empty() and not r.children.is_empty():
		var b: MathBox = r.children[0]
		var s := b.font_size
		_empty.append({"row": r, "rect": Rect2(origin + b.at + Vector2(0.0, -s * EMPTY_TOP), Vector2(b.w, s * EMPTY_TOP))})
		xs.append(origin.x + b.at.x)
	else:
		for b in real:
			xs.append(origin.x + b.at.x)
		xs.append(origin.x + r.w)
	_places.append({"row": r, "xs": xs, "y": origin.y, "size": r.font_size})
	for b in real:
		if _is_holder(b):
			for part in b.children:
				_collect(part, origin + b.at + part.at, stand_ins)


func _box_style() -> StyleBox:
	return _style("focus" if has_focus() and editable else "normal")


func _get_minimum_size() -> Vector2:
	var sb := _style("normal")
	return Vector2(_content.x + END_ROOM * 2.0, _content.y) + sb.get_minimum_size()


## Where the maths' baseline starts in the box: centred (or to the left) across, and
## centred top to bottom.
func _shift() -> Vector2:
	var sb := _style("normal")
	var inner := size - sb.get_minimum_size()
	var across := 0.0 if alignment == HORIZONTAL_ALIGNMENT_LEFT else (inner.x - _content.x) / 2.0
	return Vector2(sb.get_margin(SIDE_LEFT) + across,
		sb.get_margin(SIDE_TOP) + (inner.y - _content.y) / 2.0) + _origin


## The cursor places in the box's coordinates. For tests and taps.
func places() -> Array:
	var shift := _shift()
	return _places.map(func(p): return {"row": p.row, "xs": p.xs.map(func(x): return x + shift.x), "y": p.y + shift.y, "size": p.size})


func _draw() -> void:
	draw_style_box(_box_style(), Rect2(Vector2.ZERO, size))
	var font := _font()
	var s := _size()
	var color := get_theme_color("font_color", "LineEdit")
	var shift := _shift()
	if root.children.is_empty():
		draw_string(font, shift, placeholder_text, HORIZONTAL_ALIGNMENT_LEFT, -1, s, get_theme_color("font_placeholder_color", "LineEdit"))
	else:
		root.draw(self, font, shift, color)
	var typing := has_focus() and editable
	for part in _empty:
		var r := Rect2(part.rect.position + shift, part.rect.size)
		# The cursor in an empty part fills its box, as on the TI.
		if typing and part.row == row:
			draw_rect(r, Color(color, 0.45))
		_dashed(r, Color(color, 0.7), maxf(2.0, s * 0.04))
	if typing and (row == root or not row.children.is_empty()):
		_draw_caret(shift, color)


func _draw_caret(shift: Vector2, color: Color) -> void:
	for p in _places:
		if p.row != row:
			continue
		var s: float = p.size
		var x: float = p.xs[mini(at, p.xs.size() - 1)] + shift.x
		var y: float = p.y + shift.y
		draw_rect(Rect2(x - CARET / 2.0, y - s * MathBox.INK_ASCENT, CARET, s * (MathBox.INK_ASCENT + MathBox.INK_DESCENT)), color)
		return


func _dashed(r: Rect2, color: Color, width: float) -> void:
	var dash := maxf(4.0, r.size.y * DASH)
	var corners := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	for i in 4:
		draw_dashed_line(corners[i], corners[(i + 1) % 4], color, width, dash)
