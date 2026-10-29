class_name Credits
extends Control
## The game's credits (FAL-419), opened from the title screen: third-party code, fonts and
## sound from data/credits.json, each with its licence notice, then Godot's own licence
## (Engine.get_license_text()). Each code notice is also at the top of the file that
## uses it (engine/expr.gd, engine/brent.gd).

const DATA := "res://data/credits.json"


static func make() -> Credits:
	var c := Credits.new()
	c.name = "Credits"
	c._build()
	return c


## The credits' sections, as data/credits.json lists them.
static func sections() -> Array:
	var d = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	return d.get("sections", []) if d is Dictionary else []


func _build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color(UiTheme.BG, 0.97)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 48)
	add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 20)
	margin.add_child(col)
	var head := HBoxContainer.new()
	var title := UiTheme.label("Credits", 84, UiTheme.TEAL)
	title.add_theme_font_override("font", UiTheme.TITLE_FONT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var close := Button.new()
	close.name = "Close"
	close.text = "Close"
	close.pressed.connect(queue_free)
	head.add_child(close)
	col.add_child(head)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	var list := VBoxContainer.new()
	list.name = "List"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 14)
	scroll.add_child(list)
	for s in sections():
		list.add_child(UiTheme.label(s.title, UiTheme.BIG, UiTheme.SAND))
		list.add_child(UiTheme.label("%s\nLicence: %s. Used in %s." % [s.what, s.licence, s.used_in], UiTheme.SMALL))
		var notice: String = Engine.get_license_text() if s.notice == "godot" else s.notice
		list.add_child(UiTheme.label(notice, UiTheme.SMALL - 6, UiTheme.DIM))
