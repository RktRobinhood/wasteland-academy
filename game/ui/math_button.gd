class_name MathButton
extends Button
## A button whose label can raise powers and lower subscripts (FAL-760): the options and the
## worked solution's method tabs. A Button can't hold rich text, so text with either is
## drawn by a RichTextLabel inside it, and the button's height is set by hand from that
## label's, never less than one line's. Its colour follows the button's state and theme
## colours (font_disabled_color and the rest), as the button's own text would. Plain text
## stays the Button's own `text`. Set `math`; it keeps the text as written.

var math := "":
	set(v):
		math = v
		var scripted := UiTheme.scripted(v)
		text = "" if scripted else v
		if scripted and _label == null:
			_label = UiTheme.rich()
			_label.name = "Math"
			add_child(_label, false, Node.INTERNAL_MODE_FRONT)
		elif not scripted and _label != null:
			remove_child(_label)
			_label.queue_free()
			_label = null
			custom_minimum_size.y = 0
		_render()

var _label: RichTextLabel


func _notification(what: int) -> void:
	if _label == null:
		return
	match what:
		NOTIFICATION_THEME_CHANGED:
			_render()
		NOTIFICATION_RESIZED:
			_layout()
		NOTIFICATION_DRAW:
			_sync_color.call_deferred()


func _render() -> void:
	if _label == null:
		return
	var size := get_theme_font_size("font_size")
	_label.add_theme_font_size_override("normal_font_size", size)
	_label.clear()
	UiTheme.add_math(_label, math, size)
	_layout()
	_sync_color()


## The label inside the margins, centred down the button, and the button as tall as it.
func _layout() -> void:
	var sb := get_theme_stylebox("normal")
	var width := size.x - sb.get_margin(SIDE_LEFT) - sb.get_margin(SIDE_RIGHT)
	if width <= 0.0:
		return
	_label.size = Vector2(width, 0)
	var h := maxf(_label.get_content_height(), get_theme_font("font").get_height(get_theme_font_size("font_size")))
	_label.size = Vector2(width, h)
	var tall := ceilf(h + sb.get_margin(SIDE_TOP) + sb.get_margin(SIDE_BOTTOM))
	_label.position = Vector2(sb.get_margin(SIDE_LEFT), roundf((maxf(size.y, tall) - h) / 2.0))
	if custom_minimum_size.y != tall:
		custom_minimum_size.y = tall


func _sync_color() -> void:
	if _label == null:
		return
	var key: String = {DRAW_PRESSED: "font_pressed_color", DRAW_HOVER: "font_hover_color",
		DRAW_DISABLED: "font_disabled_color", DRAW_HOVER_PRESSED: "font_hover_pressed_color"}.get(get_draw_mode(),
		"font_focus_color" if has_focus() else "font_color")
	var c := get_theme_color(key)
	if _label.get_theme_color("default_color") != c:
		_label.add_theme_color_override("default_color", c)
