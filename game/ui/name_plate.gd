class_name NamePlate
extends RefCounted
## The player's name plate (G6): the frame and the tint bought at the Bazaar
## (engine/bazaar.gd). The fight screen shows it over the player's HP bar, and the
## Bazaar shows it as the preview. With nothing worn it is a plain panel in Scrap Teal.


## The frame worn, as Bazaar.FRAMES has it, or {} for the plain plate.
static func frame_of(save: Dictionary) -> Dictionary:
	return Bazaar.FRAMES.get(Bazaar.record(save).frame, {})


## The tint worn, or Scrap Teal with none.
static func tint_of(save: Dictionary) -> Color:
	return (Bazaar.TINTS.get(Bazaar.record(save).tint, {}) as Dictionary).get("color", UiTheme.TEAL)


## A plate reading `text`, in the frame and tint of `frame_id` and `tint_id` ("" for
## none), at font size `size`.
static func make(text: String, frame_id: String, tint_id: String, size: int = UiTheme.SMALL) -> PanelContainer:
	var box := PanelContainer.new()
	box.name = "NamePlate"
	box.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var frame: Dictionary = Bazaar.FRAMES.get(frame_id, {})
	var pad := roundi(size * 0.7)
	if frame.is_empty():
		var sb := UiTheme.panel(UiTheme.PANEL_HI)
		sb.set_corner_radius_all(10)
		_pad(sb, pad, roundi(size * 0.25))
		box.add_theme_stylebox_override("panel", sb)
	else:
		var sb := StyleBoxTexture.new()
		sb.texture = load(frame.art)
		var m: Array = frame.margins
		sb.texture_margin_left = m[0]
		sb.texture_margin_top = m[1]
		sb.texture_margin_right = m[2]
		sb.texture_margin_bottom = m[3]
		_pad(sb, pad + int(m[0]), roundi(size * 0.25) + int(m[1]))
		box.add_theme_stylebox_override("panel", sb)
	var l := UiTheme.label(text, size, (Bazaar.TINTS.get(tint_id, {}) as Dictionary).get("color", UiTheme.TEAL))
	l.name = "Text"
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", UiTheme.TITLE_FONT)
	l.add_theme_color_override("font_outline_color", UiTheme.BG)
	l.add_theme_constant_override("outline_size", maxi(6, roundi(size * 0.22)))
	box.add_child(l)
	return box


## The plate the save wears.
static func for_save(save: Dictionary, text: String = "YOU", size: int = UiTheme.SMALL) -> PanelContainer:
	var rec := Bazaar.record(save)
	return make(text, rec.frame, rec.tint, size)


static func _pad(sb: StyleBox, side: int, top: int) -> void:
	sb.content_margin_left = side
	sb.content_margin_right = side
	sb.content_margin_top = top
	sb.content_margin_bottom = top
