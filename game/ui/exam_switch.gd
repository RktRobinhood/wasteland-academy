class_name ExamSwitch
extends VBoxContainer
## The exam switch (#203, string audit R8, R9, P2): a two-way choice between "Exam
## questions only" and "Exam questions plus training", with one line of help. It is the
## save's settings.exam_only. A new save starts on plus training (SaveData.blank()).
## The map's topic screen and the practice screen both use it.

const ONLY := "Exam questions only"
const PLUS := "Exam questions plus training"
const HELP := "Training adds concept checks and warm-ups you won't see on a paper."

## The "Exam questions only" button; its toggled(on) is the setting's new value.
var only: Button
var plus: Button


## A switch showing `exam_only`. `changed` is called with the new value when the student
## picks the other side.
static func make(exam_only: bool, changed: Callable) -> ExamSwitch:
	var s := ExamSwitch.new()
	s.name = "ExamSwitch"
	s.add_theme_constant_override("separation", 6)
	var row := HBoxContainer.new()
	row.name = "Row"
	row.add_theme_constant_override("separation", 12)
	s.add_child(row)
	var group := ButtonGroup.new()
	s.only = s._button("ExamOnly", ONLY, group, exam_only)
	s.plus = s._button("ExamPlusTraining", PLUS, group, not exam_only)
	row.add_child(s.only)
	row.add_child(s.plus)
	var help := UiTheme.label(HELP, UiTheme.SMALL, UiTheme.DIM)
	help.name = "Help"
	s.add_child(help)
	s.only.toggled.connect(changed)
	return s


func _button(n: String, text: String, group: ButtonGroup, pressed: bool) -> Button:
	var b := Button.new()
	b.name = n
	b.text = text
	b.toggle_mode = true
	b.button_group = group
	b.set_pressed_no_signal(pressed)
	b.add_theme_font_size_override("font_size", UiTheme.SMALL)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return b


## Shows `exam_only` without calling `changed`.
func show_value(exam_only: bool) -> void:
	only.set_pressed_no_signal(exam_only)
	plus.set_pressed_no_signal(not exam_only)
