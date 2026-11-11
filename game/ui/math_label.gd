class_name MathLabel
extends Control
## Maths drawn as on paper (FAL-797): a MathBox tree, with fractions stacked over a bar,
## powers raised and roots under a radical sign. Set text to have MathBox.parse() cut the
## tree from it, or set box to draw a tree built elsewhere.
##
## It wraps at spaces in the tree's top row like an autowrap Label, never inside a
## fraction, a power or a root, and is sized like one: no minimum width, and the height
## its lines need at its width. Its font, size and colour come from the theme as a
## Label's do, and "font_color" and "font_size" overrides work the same, so code that
## recolours a feedback line needs no change.
##
## Inside a Button (UiTheme.math_button), it takes the button's text colour for its state
## (hover, pressed, disabled) and the button's font size, as the button's own text would.

const LINE_SEPARATION := 3

## The maths, with slashes and carets as the questions write it.
var text := "":
	set(v):
		if v == text:
			return
		text = v
		box = MathBox.parse(v)
## The tree it draws. Setting it leaves text as it was.
var box := MathBox.row():
	set(v):
		box = v
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

## Each word: a laid-out MathBox row, or "\n", or " ". _words is the one in use:
## _drawn_roots, or _open_roots, where each root is written √(…) as text, so a root too
## wide for the line can wrap at its spaces.
var _words: Array = []
var _drawn_roots: Array = []
var _open_roots: Array = []
## The two share their boxes, and a box keeps where it sits in the word laid out last.
var _laid_words: Array = []
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
	return box.plain()


## What it draws, where, in its own coordinates, as MathBox.drawn() lists it. For tests.
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
			out.append_array(xw[1].drawn(Vector2(x0 + xw[0], y0 + l.base)))
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
	_space = font.get_string_size(" ", HORIZONTAL_ALIGNMENT_LEFT, -1, s).x
	_drawn_roots = _split(box.children, font, s)
	var has_root := box.children.any(func(n: MathBox): return n.kind == MathBox.Kind.ROOT)
	_open_roots = _split(_opened(box.children), font, s) if has_root else _drawn_roots
	_laid_words = _open_roots
	_laid_width = -1.0
	_layout()


## items with each root written out as √(…) in text.
static func _opened(items: Array) -> Array:
	var out := []
	for n: MathBox in items:
		if n.kind == MathBox.Kind.ROOT:
			out.append(MathBox.text_box("√("))
			out.append_array(n.children[0].children)
			out.append(MathBox.text_box(")"))
		else:
			out.append(n)
	return out


## The words of a row's items, cut at the spaces in its text.
func _split(items: Array, font: Font, s: int) -> Array:
	var words := []
	var word := []
	for n: MathBox in items:
		if n.kind == MathBox.Kind.TEXT:
			var parts: PackedStringArray = n.text.replace("\n", " \n ").split(" ")
			for k in parts.size():
				if k > 0:
					_end_word(words, word, font, s)
					word = []
					if parts[k] != "\n":
						words.append(" ")
				if parts[k] == "\n":
					if not words.is_empty() and words.back() is String and words.back() == " ":
						words.pop_back()
					words.append("\n")
				elif parts[k] != "":
					word.append(MathBox.text_box(parts[k]))
		else:
			word.append(n)
	_end_word(words, word, font, s)
	return words


static func _end_word(words: Array, word: Array, font: Font, s: int) -> void:
	if word.is_empty():
		return
	var w := MathBox.row(word)
	w.layout(font, s)
	words.append(w)


## Lays the words out in lines at the current width.
func _layout() -> void:
	_laid_width = size.x
	_words = _drawn_roots
	if autowrap and not is_same(_open_roots, _drawn_roots) and size.x > 0.0:
		for w in _drawn_roots:
			if w is MathBox and w.w > size.x and w.children.any(func(n: MathBox): return n.kind == MathBox.Kind.ROOT):
				_words = _open_roots
				break
	if not is_same(_words, _laid_words):
		for w in _words:
			if w is MathBox:
				w.layout(_font(), font_size())
		_laid_words = _words
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
		MathBox.draw_piece(self, font, d, color)
