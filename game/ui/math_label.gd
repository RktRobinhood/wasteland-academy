class_name MathLabel
extends Control
## Maths drawn as on paper (FAL-797): fractions stacked over a bar and powers raised, cut
## by MathText.parse(). It wraps at spaces like an autowrap Label, never inside a fraction
## or a power, and is sized like one: no minimum width, and the height its lines need at
## its width. Its font, size and colour come from the theme as a Label's do, and
## "font_color" and "font_size" overrides work the same, so code that recolours a
## feedback line needs no change.
##
## Inside a Button (UiTheme.math_button), it takes the button's text colour for its state
## (hover, pressed, disabled) and the button's font size, as the button's own text would.
##
## A fraction's top and bottom are FRACTION_SCALE of the line's size, and a fraction in a
## fraction shrinks again, but never below a power's size, so the smallest numbers stay
## readable on a phone. In a power, a fraction keeps the power's size.

## The line's size for a fraction's top and bottom.
const FRACTION_SCALE := 0.85
## The bar's height above the baseline, about the middle of a minus sign, as a share of
## the size. The bar's thickness and the gaps above and below it, likewise.
const AXIS := 0.3
const BAR := 0.06
const GAP := 0.1
## How far the bar runs past the wider of the top and bottom, and the space either side.
const OVERHANG := 0.08
const SIDE := 0.05
## The height of a number or letter above and below the baseline, as a share of the
## size, for stacking. A line is never less than the font's own height.
const INK_ASCENT := 0.8
const INK_DESCENT := 0.24
const LINE_SEPARATION := 3

## The maths, with slashes and carets as the questions write it.
var text := "":
	set(v):
		if v == text:
			return
		text = v
		_nodes = MathText.parse(v)
		_rebuild()
var horizontal_alignment := HORIZONTAL_ALIGNMENT_LEFT:
	set(v):
		horizontal_alignment = v
		queue_redraw()
## False keeps it on one line, as wide as its text, like a Label with autowrap off.
var autowrap := true:
	set(v):
		autowrap = v
		_rebuild()
## The button it's drawn on, if any: its colour follows the button's state.
var button: Button:
	set(v):
		button = v
		if v != null:
			v.draw.connect(queue_redraw)
		_rebuild()

var _nodes: Array = []
## Each word: {"w", "asc", "desc", "ops"}, or "\n", or " ". An op is
## ["text", Vector2 (x, baseline), string, size] or ["bar", Rect2], from the word's
## left end and the line's baseline.
var _words: Array = []
var _space := 0.0
## Each line: {"words": [[x, word]], "w", "base"}, at the current width.
var _lines: Array = []
var _height := 0.0
var _width := 0.0
var _laid_width := -1.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## The text as a line, without the carets: as RichTextLabel.get_parsed_text().
func get_parsed_text() -> String:
	return MathText.plain(_nodes)


## What it draws, where, in its own coordinates: {"text", "at" (the baseline's left
## end), "size"} for each piece of text and {"bar": Rect2} for each fraction's bar. For
## tests.
func drawn() -> Array:
	var out := []
	# On a button, the lines are centred top to bottom, as a button's own text is.
	var y0 := maxf(0.0, (size.y - _height) / 2.0) if button != null else 0.0
	for l in _lines:
		var x0 := 0.0
		if horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER:
			x0 = (size.x - l.w) / 2.0
		elif horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT:
			x0 = size.x - l.w
		for xw in l.words:
			var origin := Vector2(x0 + xw[0], y0 + l.base)
			for op in xw[1].ops:
				if op[0] == "text":
					out.append({"text": op[2], "at": origin + op[1], "size": op[3]})
				else:
					out.append({"bar": Rect2(origin + op[1].position, op[1].size)})
	return out


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_THEME_CHANGED:
			_rebuild()
		NOTIFICATION_RESIZED:
			if not is_equal_approx(size.x, _laid_width):
				_layout()


func _get_minimum_size() -> Vector2:
	return Vector2(0.0 if autowrap else _width, _height)


func font_size() -> int:
	if button != null:
		return button.get_theme_font_size("font_size")
	if has_theme_font_size_override("font_size"):
		return get_theme_font_size("font_size")
	return get_theme_font_size("font_size", "Label")


func _font() -> Font:
	if has_theme_font_override("font"):
		return get_theme_font("font")
	return (button if button != null else self).get_theme_font("font", "Button" if button != null else "Label")


func _color() -> Color:
	if button != null:
		var name := "font_color"
		match button.get_draw_mode():
			BaseButton.DRAW_PRESSED:
				name = "font_pressed_color"
			BaseButton.DRAW_HOVER:
				name = "font_hover_color"
			BaseButton.DRAW_DISABLED:
				name = "font_disabled_color"
			BaseButton.DRAW_HOVER_PRESSED:
				name = "font_hover_pressed_color"
			_:
				if button.has_focus():
					name = "font_focus_color"
		return button.get_theme_color(name)
	if has_theme_color_override("font_color"):
		return get_theme_color("font_color")
	return get_theme_color("font_color", "Label")


## Measures every word again, for a new text or theme, then lays the lines out.
func _rebuild() -> void:
	var font := _font()
	var s := font_size()
	_words.clear()
	_space = font.get_string_size(" ", HORIZONTAL_ALIGNMENT_LEFT, -1, s).x
	var word := []
	for n in _nodes:
		if n is String:
			var parts: PackedStringArray = n.replace("\n", " \n ").split(" ")
			for k in parts.size():
				if k > 0:
					_end_word(word, font, s)
					word = []
					if parts[k] != "\n":
						_words.append(" ")
				if parts[k] == "\n":
					if not _words.is_empty() and _words.back() is String and _words.back() == " ":
						_words.pop_back()
					_words.append("\n")
				elif parts[k] != "":
					word.append(parts[k])
		else:
			word.append(n)
	_end_word(word, font, s)
	_laid_width = -1.0
	_layout()


func _end_word(word: Array, font: Font, s: int) -> void:
	if word.is_empty():
		return
	_words.append(_row(word, font, s, s, false))


## Lays the words out in lines at the current width.
func _layout() -> void:
	_laid_width = size.x
	var font := _font()
	var s := font_size()
	var line_asc := font.get_ascent(s)
	var line_desc := font.get_descent(s)
	_lines.clear()
	var line := {"words": [], "w": 0.0, "asc": line_asc, "desc": line_desc}
	var pending_space := false
	_width = 0.0
	for w in _words:
		if w is String:
			if w == "\n":
				_lines.append(line)
				line = {"words": [], "w": 0.0, "asc": line_asc, "desc": line_desc}
				pending_space = false
			else:
				pending_space = not line.words.is_empty()
			continue
		var x: float = line.w + (_space if pending_space else 0.0)
		if autowrap and not line.words.is_empty() and x + w.w > size.x:
			_lines.append(line)
			line = {"words": [], "w": 0.0, "asc": line_asc, "desc": line_desc}
			x = 0.0
		line.words.append([x, w])
		line.w = x + w.w
		line.asc = maxf(line.asc, w.asc)
		line.desc = maxf(line.desc, w.desc)
		pending_space = false
	_lines.append(line)
	var y := 0.0
	for l in _lines:
		l.base = y + l.asc
		y += l.asc + l.desc + LINE_SEPARATION
		_width = maxf(_width, l.w)
	var h := ceilf(y - LINE_SEPARATION)
	if h != _height or not autowrap:
		_height = h
		update_minimum_size()
	queue_redraw()


func _draw() -> void:
	var font := _font()
	var color := _color()
	for d in drawn():
		if d.has("bar"):
			draw_rect(d.bar, color)
		else:
			draw_string(font, d.at, d.text, HORIZONTAL_ALIGNMENT_LEFT, -1, d.size, color)


## Nodes side by side on one line, at size s: {"w", "asc", "desc", "ops"}. base is the
## line's own size, for the smallest a fraction may get.
func _row(nodes: Array, font: Font, s: int, base: int, in_power: bool) -> Dictionary:
	var out := {"w": 0.0, "asc": 0.0, "desc": 0.0, "ops": []}
	for n in nodes:
		var b: Dictionary
		if n is String:
			b = {"w": font.get_string_size(n, HORIZONTAL_ALIGNMENT_LEFT, -1, s).x, "asc": s * INK_ASCENT,
				"desc": s * INK_DESCENT, "ops": [["text", Vector2.ZERO, n, s]]}
		elif n.has("pow"):
			b = _power(n.pow, font, s, base)
		else:
			b = _fraction(n, font, s, base, in_power)
		_append(out, b, Vector2(out.w, 0.0))
		out.w += b.w
	return out


func _power(nodes: Array, font: Font, s: int, base: int) -> Dictionary:
	var ps := roundi(s * UiTheme.POWER_SCALE)
	var inner := _row(nodes, font, ps, base, true)
	# As UiTheme's raised font: up by a share of the power's own line height.
	var rise := -UiTheme.POWER_RAISE * font.get_height(ps)
	var out := {"w": inner.w, "asc": maxf(s * INK_ASCENT, rise + inner.asc), "desc": maxf(0.0, inner.desc - rise), "ops": []}
	_append(out, inner, Vector2(0.0, -rise))
	return out


func _fraction(n: Dictionary, font: Font, s: int, base: int, in_power: bool) -> Dictionary:
	var fs := s if in_power else maxi(roundi(s * FRACTION_SCALE), roundi(base * UiTheme.POWER_SCALE))
	var top := _row(n.num, font, fs, base, in_power)
	var bottom := _row(n.den, font, fs, base, in_power)
	var bar := maxf(2.0, roundf(s * BAR))
	var gap := s * GAP
	var axis := s * AXIS
	var side := s * SIDE
	var w := maxf(top.w, bottom.w) + 2.0 * s * OVERHANG
	var bar_top := -axis - bar / 2.0
	var out := {"w": w + 2.0 * side, "asc": axis + bar / 2.0 + gap + top.desc + top.asc,
		"desc": maxf(0.0, -axis + bar / 2.0 + gap + bottom.asc + bottom.desc), "ops": [["bar", Rect2(side, bar_top, w, bar)]]}
	_append(out, top, Vector2(side + (w - top.w) / 2.0, bar_top - gap - top.desc))
	_append(out, bottom, Vector2(side + (w - bottom.w) / 2.0, bar_top + bar + gap + bottom.asc))
	return out


## Adds b's ops to out, moved by at. Sizes stay out's own.
static func _append(out: Dictionary, b: Dictionary, at: Vector2) -> void:
	for op in b.ops:
		if op[0] == "text":
			out.ops.append(["text", op[1] + at, op[2], op[3]])
		else:
			out.ops.append(["bar", Rect2(op[1].position + at, op[1].size)])
	out.asc = maxf(out.asc, b.asc - at.y)
	out.desc = maxf(out.desc, b.desc + at.y)
