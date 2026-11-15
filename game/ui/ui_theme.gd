class_name UiTheme
extends RefCounted
## Salvage Neon colours and sizes for plain screens. Sizes are in base units (the
## 1080-wide portrait canvas): a 390 px phone shows them at about a third.
##
## Maths text uses Godot's default font (Open Sans), which has −, ², √, ≥, ≤, ½ and Δ
## but not ⁻, ∘, ↦, →, ≡, ℝ, ∈ and the like (FAL-514). install_math_font() puts a
## subset of DejaVu Sans behind it for those. The vendored Share Tech Mono has neither;
## Calculator.mono() falls back to the default font, so it gets them too.

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
const MATH_FONT := preload("res://assets/fonts/dejavu-math-subset.woff2")
## A power's size against its line, and how far up it sits, as a share of the font's height.
const POWER_SCALE := 0.68
const POWER_RAISE := -0.28
## How far down a subscript sits, as a share of the font's height (FAL-760).
const SUB_DROP := 0.12
## How far up a subscript in a power sits: under the power, over the line.
const POWER_SUB_RAISE := -0.12

static var _raised: FontVariation
static var _lowered: FontVariation
static var _raised_lowered: FontVariation


## Adds the maths subset behind the default font, once. Safe to call again.
static func install_math_font() -> void:
	var base := ThemeDB.fallback_font
	if not base.fallbacks.has(MATH_FONT):
		base.fallbacks = base.fallbacks + [MATH_FONT]


## The characters of s the game's default font stack can't draw (each once, in order of
## appearance). Whitespace and control characters never count. A box on screen means
## this is not empty; tools/check-answers and the tests fail on it.
static func missing_glyphs(s: String) -> String:
	install_math_font()
	var font := ThemeDB.fallback_font
	var out := ""
	for i in s.length():
		var ch := s.substr(i, 1)
		if ch.unicode_at(0) > 32 and not font.has_char(ch.unicode_at(0)) and not out.contains(ch):
			out += ch
	return out


static func make() -> Theme:
	install_math_font()
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


## A label for maths, with powers written with a caret drawn raised (FAL-743). They are
## raised here, not written in superscript characters, as Unicode has no superscript . or /.
## Subscripts written with an underscore (u_1, log_a b) are drawn lowered (FAL-760), as
## Unicode has no subscript b or c. Plain text gets a plain label, so only the text with
## either is rich text. The questions keep their carets: tools/check_answers.py parses them.
## A Button can't hold rich text: MathButton draws one inside it, and MathText is a
## label whose text changes.
static func math(text: String, size: int = BODY, color: Color = TEXT, center := false) -> Control:
	if not scripted(text):
		var l := label(text, size, color)
		if center:
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		return l
	var r := rich(size, color)
	r.fit_content = true
	if center:
		r.push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)
	add_math(r, text, size)
	return r


## Whether text has a power or a subscript to draw off the line.
static func scripted(text: String) -> bool:
	return Fmt.script_runs(text).any(func(run): return run[1] != 0)


## An empty rich label set up for maths, which the mouse goes through.
static func rich(size: int = BODY, color: Color = TEXT) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_color_override("default_color", color)
	r.add_theme_constant_override("line_separation", 3)
	return r


## Adds text to r, with its powers raised and its subscripts lowered, at font size size.
static func add_math(r: RichTextLabel, text: String, size: int) -> void:
	for run in Fmt.script_runs(text):
		if run[1] == 0:
			r.add_text(run[0])
		else:
			r.push_font(_script_font(run[1]), roundi(size * POWER_SCALE))
			r.add_text(run[0])
			r.pop()


static func _script_font(place: int) -> FontVariation:
	var f: FontVariation = {Fmt.RAISED: _raised, Fmt.LOWERED: _lowered, Fmt.RAISED_LOWERED: _raised_lowered}[place]
	if f == null:
		install_math_font()
		f = FontVariation.new()
		f.base_font = ThemeDB.fallback_font
		f.baseline_offset = {Fmt.RAISED: POWER_RAISE, Fmt.LOWERED: SUB_DROP, Fmt.RAISED_LOWERED: POWER_SUB_RAISE}[place]
		match place:
			Fmt.RAISED:
				_raised = f
			Fmt.LOWERED:
				_lowered = f
			_:
				_raised_lowered = f
	return f


static func panel(color: Color = PANEL) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(18)
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 22
	sb.content_margin_bottom = 22
	return sb


## Art behind a whole screen (FAL-470): cover-fitted and centred, under a wash of the
## background colour (`wash` its opacity) so the text on top stays easy to read. Add it
## right after the screen's background; show_backdrop() gives it its texture.
static func backdrop(wash: float = 0.55) -> TextureRect:
	var art := TextureRect.new()
	art.name = "Backdrop"
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.visible = false
	var tint := ColorRect.new()
	tint.name = "Wash"
	tint.color = Color(BG, wash)
	tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.add_child(tint)
	return art


## Shows a backdrop's art, or hides it (the plain background) when tex is null.
static func show_backdrop(art: TextureRect, tex: Texture2D) -> void:
	art.texture = tex
	art.visible = tex != null


## A square icon, `size` base units a side, kept in proportion.
static func icon(tex: Texture2D, size: int) -> TextureRect:
	var r := TextureRect.new()
	r.name = "Icon"
	r.texture = tex
	r.custom_minimum_size = Vector2(size, size)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## `text` set on banner art (FAL-470), `height` base units tall; the label is the banner's
## child "Text".
static func banner(tex: Texture2D, text: String, height: int, size: int, color: Color) -> Control:
	var box := Control.new()
	box.name = "Banner"
	box.custom_minimum_size.y = height
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var art := TextureRect.new()
	art.name = "Art"
	art.texture = tex
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(art)
	var l := label(text, size, color)
	l.name = "Text"
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", TITLE_FONT)
	l.add_theme_color_override("font_outline_color", BG)
	l.add_theme_constant_override("outline_size", maxi(6, roundi(size * 0.18)))
	box.add_child(l)
	return box
