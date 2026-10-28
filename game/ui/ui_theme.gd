class_name UiTheme
extends RefCounted
## Salvage Neon colours and sizes for plain screens. Sizes are in base units (the
## 1080-wide portrait canvas): a 390 px phone shows them at about a third.
##
## Maths text uses Godot's default font, which has −, ², √, ≥, ≤, ½ and Δ. The
## vendored Share Tech Mono doesn't.

const BG := Color(0.121569, 0.160784, 0.215686)
const PANEL := Color(0.16, 0.2, 0.27)
const PANEL_HI := Color(0.22, 0.27, 0.36)
const TEAL := Color(0.133333, 0.827451, 0.772549)
const PINK := Color(1, 0.239216, 0.654902)
const SAND := Color(0.917647, 0.796078, 0.454902)
const TEXT := Color(0.93, 0.94, 0.96)
const DIM := Color(0.611765, 0.639216, 0.686275)
const GRID := Color(1, 1, 1, 0.07)
const GRID_MAJOR := Color(1, 1, 1, 0.16)

const BODY := 42
const BIG := 50
const SMALL := 32

const TITLE_FONT := preload("res://assets/fonts/bangers-latin.woff2")


static func make() -> Theme:
	var t := Theme.new()
	t.default_font_size = BODY
	t.set_color("font_color", "Label", TEXT)
	for kind in ["normal", "hover", "pressed", "disabled", "focus", "hover_pressed"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = {"normal": PANEL, "hover": PANEL_HI, "pressed": PANEL_HI, "hover_pressed": PANEL_HI, "disabled": PANEL, "focus": Color(0, 0, 0, 0)}[kind]
		sb.set_corner_radius_all(14)
		sb.content_margin_left = 26
		sb.content_margin_right = 26
		sb.content_margin_top = 18
		sb.content_margin_bottom = 18
		if kind in ["pressed", "hover_pressed"]:
			sb.border_color = TEAL
			sb.set_border_width_all(5)
		if kind == "focus":
			sb.draw_center = false
			sb.border_color = Color(TEAL, 0.6)
			sb.set_border_width_all(3)
		t.set_stylebox(kind, "Button", sb)
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_pressed_color", "Button", TEAL)
	t.set_color("font_hover_pressed_color", "Button", TEAL)
	t.set_color("font_disabled_color", "Button", DIM)
	var le := StyleBoxFlat.new()
	le.bg_color = Color(0.08, 0.1, 0.14)
	le.border_color = DIM
	le.set_border_width_all(3)
	le.set_corner_radius_all(10)
	le.content_margin_left = 14
	le.content_margin_right = 14
	le.content_margin_top = 10
	le.content_margin_bottom = 10
	t.set_stylebox("normal", "LineEdit", le)
	var lf := le.duplicate()
	lf.border_color = TEAL
	t.set_stylebox("focus", "LineEdit", lf)
	t.set_color("font_color", "LineEdit", TEXT)
	t.set_font_size("font_size", "LineEdit", BIG)
	return t


static func label(text: String, size: int = BODY, color: Color = TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func panel(color: Color = PANEL) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(18)
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 22
	sb.content_margin_bottom = 22
	return sb
