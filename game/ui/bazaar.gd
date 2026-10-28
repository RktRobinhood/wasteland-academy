extends Control
## The Bazaar screen (G6): spend the Scrap banked from runs. Upgrades are kept for good
## and capped, the perk is one slot for the next run, and cosmetics are name-plate
## frames and colour tints. The rules are engine/bazaar.gd; this screen only draws them.
## It is reached from the title screen (the map, G5, links it later) and from a run's
## summary.
##
## Deep links: /next/?bazaar opens it; /next/?bazaar=demo opens it on a sample save
## with Scrap to spend and a few things bought, and stores nothing (screenshots).

const MAIN := "res://scenes/main.tscn"
const MONO := preload("res://assets/fonts/share-tech-mono-latin.woff2")
const COLUMN := 1000
const COLUMN_WIDE := 2500
## The shelves are darker than a button, so every button stands out on them.
const SHELF := Color(0.1, 0.125, 0.17)

## Where the save lives. "" stores nothing (the demo).
var save_path := SaveData.PATH
## Set before the screen enters the tree to shop on this save instead of loading one.
var save: Dictionary = {}

var margin: MarginContainer
var hud_gap: Control
var bank: Label
var message: Label
var scroll: ScrollContainer
var cols: BoxContainer
var left: VBoxContainer
var right: VBoxContainer
## "item" or "item|lifeline" -> its Button, rebuilt on every refresh().
var buttons := {}


func _ready() -> void:
	theme = UiTheme.make()
	if deep_link() == "demo":
		save_path = ""
		save = demo_save()
	elif save.is_empty():
		save = SaveData.load_from(save_path)
	Bazaar.record(save)
	_build()
	resized.connect(_fit)
	_fit()
	refresh()


## A save with Scrap to spend and a few things bought, for screenshots.
static func demo_save() -> Dictionary:
	var s := SaveData.blank()
	s.scrap = 5000
	Bazaar.buy(s, "max_hp")
	Bazaar.buy(s, "lifeline", "hint")
	Bazaar.buy(s, "frame:signal")
	Bazaar.buy(s, "tint:rust")
	Bazaar.buy(s, "field_watch")
	s.scrap = 1240
	return s


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = UiTheme.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	margin = MarginContainer.new()
	margin.name = "Margin"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(margin)
	var col := VBoxContainer.new()
	col.name = "Column"
	col.add_theme_constant_override("separation", 18)
	margin.add_child(col)

	var head := HBoxContainer.new()
	head.name = "Head"
	var title := UiTheme.label("Bazaar", 96, UiTheme.PINK)
	title.name = "Title"
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.add_theme_font_override("font", UiTheme.TITLE_FONT)
	head.add_child(title)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(spacer)
	var back := Button.new()
	back.name = "Back"
	back.text = "Back"
	back.add_theme_font_size_override("font_size", UiTheme.SMALL)
	back.pressed.connect(func(): get_tree().change_scene_to_file(MAIN))
	head.add_child(back)
	hud_gap = Control.new()
	hud_gap.name = "HudGap"
	hud_gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(hud_gap)
	col.add_child(head)

	bank = _mono("", UiTheme.BIG, UiTheme.SAND)
	bank.name = "Bank"
	col.add_child(bank)
	message = UiTheme.label("Scrap comes from runs. Every run banks some, even a short one.", UiTheme.SMALL, UiTheme.DIM)
	message.name = "Message"
	col.add_child(message)

	scroll = ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	cols = BoxContainer.new()
	cols.name = "Sections"
	cols.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", 28)
	scroll.add_child(cols)
	for side in ["Left", "Right"]:
		var v := VBoxContainer.new()
		v.name = side
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_theme_constant_override("separation", 28)
		cols.add_child(v)
	left = cols.get_node("Left")
	right = cols.get_node("Right")


func _fit() -> void:
	var wide := size.x > size.y
	var col := COLUMN_WIDE if wide else COLUMN
	var side := maxf(36.0, (size.x - col) / 2.0)
	margin.add_theme_constant_override("margin_left", int(side))
	margin.add_theme_constant_override("margin_right", int(side))
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 30)
	hud_gap.custom_minimum_size.x = maxf(0.0, AudioHud.RESERVED_RIGHT - side)
	# Two columns side by side on a PC window, one under the other on a phone.
	cols.vertical = not wide


## Draws everything again from the save.
func refresh() -> void:
	bank.text = "Scrap: %d" % int(save.scrap)
	buttons = {}
	for box in [left, right]:
		for c in box.get_children():
			box.remove_child(c)
			c.queue_free()
	left.add_child(_upgrades())
	left.add_child(_cosmetics())
	right.add_child(_perks())


## Buys an item and says how it went. A failed purchase changes nothing.
func buy(item: String, lifeline: String = "") -> Dictionary:
	var r := Bazaar.buy(save, item, lifeline)
	if r.ok:
		_store()
		Audio.play_sfx("reward")
		_say("Bought %s for %d Scrap." % [_name_of(item, lifeline), r.price], UiTheme.TEAL)
	else:
		_say(r.reason, UiTheme.PINK)
	refresh()
	return r


func wear(item: String) -> void:
	if Bazaar.wear(save, item):
		_store()
		Audio.play_sfx("confirm")
	refresh()


func _store() -> void:
	if save_path != "":
		SaveData.store(save, save_path)


func _say(text: String, color: Color) -> void:
	message.text = text
	message.add_theme_color_override("font_color", color)


func _name_of(item: String, lifeline: String) -> String:
	if Bazaar.UPGRADES.has(item):
		return Bazaar.UPGRADES[item].name + (" (%s)" % Bazaar.LIFELINE_NAMES[lifeline] if lifeline != "" else "")
	if Bazaar.PERKS.has(item):
		return Bazaar.perk_name({"id": item, "lifeline": lifeline})
	var parts := item.split(":")
	return (Bazaar.FRAMES if parts[0] == "frame" else Bazaar.TINTS)[parts[1]].name


# ── Sections ─────────────────────────────────────────────────

func _section(id: String, heading: String, note: String) -> Array:
	var box := PanelContainer.new()
	box.name = id
	box.add_theme_stylebox_override("panel", UiTheme.panel(SHELF))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	box.add_child(v)
	var h := UiTheme.label(heading, 64, UiTheme.TEAL)
	h.add_theme_font_override("font", UiTheme.TITLE_FONT)
	v.add_child(h)
	v.add_child(UiTheme.label(note, UiTheme.SMALL, UiTheme.DIM))
	return [box, v]


## One item: its name and what it does, a line on where it stands, and its buttons.
func _row(v: VBoxContainer, name: String, text: String, status: String) -> HBoxContainer:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.add_child(UiTheme.label(name, UiTheme.BIG, UiTheme.SAND))
	row.add_child(UiTheme.label(text, UiTheme.SMALL))
	if status != "":
		row.add_child(_mono(status, UiTheme.SMALL, UiTheme.DIM))
	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 14)
	row.add_child(btns)
	v.add_child(row)
	return btns


## A buy button for an item (and lifeline), disabled while it can't be bought.
func _buy_button(item: String, lifeline: String = "", label: String = "") -> Button:
	var b := Button.new()
	var key := item + ("|" + lifeline if lifeline != "" else "")
	b.name = key.replace(":", "_").replace("|", "_")
	var cost := Bazaar.price(save, item)
	var why := Bazaar.why_not(save, item, lifeline)
	if cost < 0:
		b.text = (label + "\n" if label != "" else "") + "Maxed"
	else:
		b.text = (label + "\n" if label != "" else "") + "%d Scrap" % cost
	b.disabled = why != ""
	b.tooltip_text = why
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", UiTheme.SMALL)
	b.pressed.connect(buy.bind(item, lifeline))
	buttons[key] = b
	return b


func _upgrades() -> Control:
	var made := _section("Upgrades", "Upgrades", "Kept for good, on every run.")
	var v: VBoxContainer = made[1]
	var rec := Bazaar.record(save)
	var hp := Tuning.BASE_HP + Tuning.MAX_HP_STEP * Bazaar.level(save, "max_hp")
	var hp_max := Tuning.BASE_HP + Tuning.MAX_HP_STEP * Bazaar.cap("max_hp")
	_row(v, Bazaar.UPGRADES.max_hp.name, Bazaar.UPGRADES.max_hp.text,
			"Max HP %d of %d · bought %d of %d" % [hp, hp_max, Bazaar.level(save, "max_hp"), Bazaar.cap("max_hp")]) \
			.add_child(_buy_button("max_hp"))
	var got := []
	for id in rec.lifelines:
		if int(rec.lifelines[id]) > 0:
			got.append("%s +%d" % [Bazaar.LIFELINE_NAMES[id], int(rec.lifelines[id])])
	var btns := _row(v, Bazaar.UPGRADES.lifeline.name, Bazaar.UPGRADES.lifeline.text,
			"Bought %d of %d%s" % [Bazaar.level(save, "lifeline"), Bazaar.cap("lifeline"),
			(": " + ", ".join(got)) if not got.is_empty() else ""])
	for id in Bazaar.LIFELINE_NAMES:
		btns.add_child(_buy_button("lifeline", id, _short(id)))
	return made[0]


func _perks() -> Control:
	var made := _section("Perks", "Perk", "One perk, for your next run only. It's used up when the run starts.")
	var v: VBoxContainer = made[1]
	var perk: Dictionary = Bazaar.record(save).perk
	var slot := UiTheme.label(("Ready for your next run: " + Bazaar.perk_name(perk)) if not perk.is_empty()
			else "Your slot is empty.", UiTheme.BODY, UiTheme.TEAL if not perk.is_empty() else UiTheme.DIM)
	slot.name = "Slot"
	v.add_child(slot)
	for id in Bazaar.PERKS:
		var btns := _row(v, Bazaar.PERKS[id].name, Bazaar.PERKS[id].text, "")
		if id in Bazaar.PICK_LIFELINE:
			for l in Bazaar.LIFELINE_NAMES:
				btns.add_child(_buy_button(id, l, _short(l)))
		else:
			btns.add_child(_buy_button(id))
	return made[0]


func _cosmetics() -> Control:
	var made := _section("Cosmetics", "Name plate", "Frames and colours for your name plate and HP bar. Looks only.")
	var v: VBoxContainer = made[1]
	var rec := Bazaar.record(save)
	var preview := NamePlate.for_save(save, "YOU", 72)
	preview.name = "Preview"
	preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(preview)
	for kind in ["frame", "tint"]:
		v.add_child(UiTheme.label("Frames" if kind == "frame" else "Colours", UiTheme.BIG, UiTheme.SAND))
		var grid := GridContainer.new()
		grid.name = "Frames" if kind == "frame" else "Tints"
		grid.columns = 5 if kind == "tint" else 4
		grid.add_theme_constant_override("h_separation", 12)
		grid.add_theme_constant_override("v_separation", 12)
		v.add_child(grid)
		var table: Dictionary = Bazaar.FRAMES if kind == "frame" else Bazaar.TINTS
		for id in [""] + table.keys():
			var item: String = kind + ":" + id
			var cell := VBoxContainer.new()
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cell.add_theme_constant_override("separation", 8)
			var holder := CenterContainer.new()
			holder.custom_minimum_size.y = 90
			holder.add_child(NamePlate.make("YOU", id if kind == "frame" else rec.frame, id if kind == "tint" else rec.tint))
			cell.add_child(holder)
			var title := UiTheme.label("Plain" if id == "" and kind == "frame" else ("Teal" if id == "" else table[id].name),
					UiTheme.SMALL - 4, UiTheme.TEXT)
			title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cell.add_child(title)
			if id == "" or item in rec.owned:
				var b := Button.new()
				b.name = item.replace(":", "_") + "_wear"
				var on: bool = rec[kind] == id
				b.text = "Worn" if on else "Wear"
				b.disabled = on
				b.add_theme_font_size_override("font_size", UiTheme.SMALL - 4)
				b.pressed.connect(wear.bind(item))
				buttons[item + "|wear"] = b
				cell.add_child(b)
			else:
				var b := _buy_button(item)
				b.add_theme_font_size_override("font_size", UiTheme.SMALL - 4)
				cell.add_child(b)
			grid.add_child(cell)
	return made[0]


func _short(lifeline: String) -> String:
	return "Freeze" if lifeline == "freeze" else Bazaar.LIFELINE_NAMES[lifeline]


func _mono(text: String, size: int, color: Color = UiTheme.TEXT) -> Label:
	var l := UiTheme.label(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.add_theme_font_override("font", MONO)
	return l


## "demo", "open", or "" when the URL (web) or command line doesn't ask for the Bazaar.
static func deep_link() -> String:
	var found := ""
	if OS.has_feature("web"):
		var search = JavaScriptBridge.eval("window.location.search", true)
		if search is String and search.length() > 1:
			for part in search.substr(1).split("&"):
				var kv: PackedStringArray = part.split("=", true, 1)
				if kv[0] == "bazaar":
					found = "demo" if kv.size() == 2 and kv[1] == "demo" else "open"
	for a in OS.get_cmdline_user_args():
		if a == "--bazaar":
			found = "open"
		elif a == "--bazaar=demo":
			found = "demo"
	return found
