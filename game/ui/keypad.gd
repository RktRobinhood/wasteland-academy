class_name Keypad
extends VBoxContainer
## On-screen keys, so a phone needs no system keyboard (FAL-419). One keypad for typed
## answers (ANSWER_KEYS) and the calculator, which puts its function rows above the same
## answer keys. A key press emits `key` with the key's text.
##
##   var pad := Keypad.make()                              # typed answers
##   var pad := Keypad.make(Keypad.CALC_ROWS, Keypad.CALC_LAST)  # the calculator
##   pad.key.connect(func(k): ...)

signal key(k: String)

## The answer keys: two rows of seven.
const ANSWER_KEYS := ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", ".", "/", "−", "Del"]
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
