class_name MathText
extends RichTextLabel
## A line of maths whose text changes, with powers raised and subscripts lowered (FAL-760):
## the feedback after an answer and the fight's hint. Set `math`, not `text`: it keeps the
## carets as written, which is what the tests read. set_color() is a Label's font_color.

var math := "":
	set(v):
		math = v
		clear()
		UiTheme.add_math(self, v, _size)

var _size: int


func _init(size: int = UiTheme.BODY, color: Color = UiTheme.TEXT) -> void:
	_size = size
	fit_content = true
	scroll_active = false
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_font_size_override("normal_font_size", size)
	add_theme_constant_override("line_separation", 3)
	set_color(color)


func set_color(color: Color) -> void:
	add_theme_color_override("default_color", color)
