class_name Keypad
extends VBoxContainer
## On-screen keys, so a phone needs no system keyboard (FAL-419). One keypad for typed
## answers (ANSWER_KEYS) and the calculator, which puts its function rows above the same
## answer keys. A key press emits `key` with the key's text.
##
##   var pad := Keypad.make_answer()                       # typed answers
##   var pad := Keypad.make(Keypad.CALC_ROWS, Keypad.CALC_LAST)  # the calculator
##   pad.key.connect(func(k): ...)

signal key(k: String)

## The answer keys: two rows of seven. In an answer box, "/" is the fraction key
## (MathEntry, FAL-812), drawn as a fraction of two empty boxes; the calculator types a /.
const ANSWER_KEYS := ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", ".", "/", "−", "Del"]
## Below the answer keys in an answer box: the cursor keys.
const ANSWER_LAST := ["◀", "▶"]
const COLUMNS := 7
## The calculator's function rows, above the answer keys, and its last row below them.
const CALC_ROWS := [["sin", "cos", "tan", "ln", "log", "√", "^"], ["(", ")", "π", "e", "x", "Ans", "×"]]
const CALC_LAST := ["+", "AC", "EXE"]
## Keys that are functions or operations, not digits (the calculator draws them orange).
const FUNCTION_KEYS := ["sin", "cos", "tan", "ln", "log", "√", "^", "(", ")", "π", "e", "x", "Ans", "×", "+",
	"/", "−", "AC"]
const KEY_SIZE := Vector2(120, 104)

## key text -> Button
var buttons := {}


static func make(rows_above: Array = [], last_row: Array = []) -> Keypad:
	var pad := Keypad.new()
	pad.name = "Keypad"
	pad.add_theme_constant_override("separation", 10)
	var grid := GridContainer.new()
	grid.name = "Keys"
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	for row in rows_above:
		for k in row:
			grid.add_child(pad._button(k))
	for k in ANSWER_KEYS:
		grid.add_child(pad._button(k))
	pad.add_child(grid)
	if not last_row.is_empty():
		var row := HBoxContainer.new()
		row.name = "Last"
		row.add_theme_constant_override("separation", 10)
		for k in last_row:
			var b := pad._button(k)
			b.size_flags_stretch_ratio = 3.0 if k == "EXE" else 1.0
			row.add_child(b)
		pad.add_child(row)
	return pad


## The typed-answer keypad: the answer keys, the fraction key drawn as a fraction, and
## ◀ ▶ below them.
static func make_answer() -> Keypad:
	var pad := make([], ANSWER_LAST)
	var b: Button = pad.buttons["/"]
	b.text = ""
	var icon := FractionIcon.new()
	icon.button = b
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	b.add_child(icon)
	return pad


func _button(k: String) -> Button:
	var b := Button.new()
	b.name = "Key_" + k
	b.text = k
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = KEY_SIZE
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", UiTheme.BIG if k.length() < 3 else UiTheme.SMALL + 6)
	b.pressed.connect(func(): key.emit(k))
	buttons[k] = b
	return b


## What a key types into a line: − as -, × as *, √ as √(, a function as its name and
## "(". "" for keys that aren't text (Del, AC, EXE).
static func typed(k: String) -> String:
	match k:
		"−":
			return "-"
		"×":
			return "*"
		"√":
			return "√("
		"sin", "cos", "tan", "ln", "log":
			return k + "("
		"Del", "AC", "EXE":
			return ""
	return k


## The fraction key's face: two dashed boxes over a bar, in the button's text colour.
class FractionIcon extends Control:
	var button: Button

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _ready() -> void:
		button.draw.connect(queue_redraw)

	func _draw() -> void:
		var name := "font_color"
		match button.get_draw_mode():
			BaseButton.DRAW_PRESSED, BaseButton.DRAW_HOVER_PRESSED:
				name = "font_pressed_color"
			BaseButton.DRAW_HOVER:
				name = "font_hover_color"
			BaseButton.DRAW_DISABLED:
				name = "font_disabled_color"
		var color := button.get_theme_color(name)
		var s := minf(size.y * 0.24, size.x * 0.24)
		var c := size / 2.0
		var bar := maxf(3.0, s * 0.14)
		draw_rect(Rect2(c.x - s * 0.8, c.y - bar / 2.0, s * 1.6, bar), color)
		for y in [c.y - bar - s * 1.15, c.y + bar + s * 0.15]:
			_dashed(Rect2(c.x - s * 0.45, y, s * 0.9, s), color)

	func _dashed(r: Rect2, color: Color) -> void:
		var corners := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
		for i in 4:
			draw_dashed_line(corners[i], corners[(i + 1) % 4], color, 3.0, maxf(4.0, r.size.y * 0.2))
