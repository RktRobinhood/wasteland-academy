extends Control
## The map (G5, FAL-417; Q3 and Q11 on the FAL-274 plan; the FAL-783 plan): the world,
## then an island, then a region's screen, then its dungeon. Each layer is a closer look
## at the place picked on the one above. One scene with three screens; show_route()
## switches between them, and MapLink keeps the address bar in step, so links such as
## /next/#functions/quadratics open a region and the browser's back button works.
##
## - The world map is the overworld painting with an invisible button over each place:
##   the five islands (the Signal Tower, Functions, is open, the other four are "coming
##   soon"), the Thunderdome (open once a second island is), the Relic Library (FAL-325,
##   locked) and the Bazaar (G6, ui/bazaar.gd). The header shows the Scrap there is to
##   spend.
## - The Functions island is a hub (FAL-531 plan): the all-regions dungeon at the tower in
##   the middle and the 8 regions around it, any of them in any order. No roads: the
##   places are fast-travel points. A locked spot waits for a Relic device. A region with
##   no built type is "coming soon", worked out from the engine, so a region lights up
##   when its situations merge. SPARK's pick (Progress.suggest()) gets a beacon and first
##   focus: a suggestion, never a gate.
## - No names on the boards. Hovering, focusing or tapping a place shows its card: the
##   name, then one line (the topic, the spot_line() progress, "Coming soon" or "Locked").
##   With a mouse or keyboard a press goes in. On a touch screen the first tap shows the
##   card and lights the place, and a second tap on the place or the card goes in.
## - Going in zooms the board into the place (ZOOM_TIME), then the next layer fades in;
##   going back zooms out. With reduced motion (reduced_motion()) it cuts.
## - The region screen sits over the region's backdrop, washed (REGION_WASH) so its text
##   keeps 4.5:1. It shows accuracy, best floor, coverage and the 3 weakest skills
##   (Progress), and starts a run on floor 1 or after a beaten boss, or opens Practice.
##
## Island art by file name (FAL-362 batch 4, FAL-783 plan): ART_DIR/background.webp or
## .png, one painting with every place painted in at SPOTS; then the buttons are invisible
## hit areas with state chips (a dark wash and a padlock, or a flag). A landmark per spot
## and state (ART_DIR/<spot>-<state>.png) still draws over it. With no painting the coded
## look draws a ring per place. Sizes and names are in game/README.md under "Map art".

const FIGHT := "res://scenes/fight.tscn"
const PRACTICE := "res://scenes/practice.tscn"
const MAIN := "res://scenes/main.tscn"
const OVERWORLD := preload("res://assets/map/overworld.png")
const ART_DIR := "res://assets/map/functions/"
## Both maps are drawn on a portrait board of this size, scaled to fit under the header.
const BOARD := Vector2(1080, 1920)
const HEADER := 190.0
const COLUMN := 1000
const COLUMN_WIDE := 1500
## A place's button on the island board, a square in board units round its point, and
## the Relic device's. A painted place fills about this square.
const HIT := 300.0
const RELIC_HIT := 160.0
## How far the board zooms into a place before the next layer shows, and how long the
## zoom and the fade take, in seconds.
const ZOOM := 2.6
const ZOOM_TIME := 0.4
const FADE_TIME := 0.25
## The wash of the background colour over a region's backdrop: the dimmest text on the
## region screen keeps 4.5:1 over every backdrop in assets/regions/ (FAL-790).
const REGION_WASH := 0.7

## The five islands, where each sits on the overworld (centre and size, in % of the
## board, measured from the art; js/router.js has the same zones) and its music.
const ISLANDS := [
	{"id": "algebra", "name": "Scrap Fields", "topic": "Numbers and algebra", "zone": Rect2(30, 18, 52, 24), "music": "scrap-fields"},
	{"id": "functions", "name": "Signal Tower", "topic": "Functions", "zone": Rect2(80, 18, 26, 26), "music": "signal-tower"},
	{"id": "geometry", "name": "Dry Flats", "topic": "Geometry and trigonometry", "zone": Rect2(15, 49, 28, 30), "music": "dry-flats"},
	{"id": "stats", "name": "Radio Spires", "topic": "Statistics and probability", "zone": Rect2(85, 51, 26, 26), "music": "radio-spires"},
	{"id": "calculus", "name": "Engine Core", "topic": "Calculus", "zone": Rect2(50, 78, 60, 24), "music": "engine-core"},
]
const THUNDERDOME_ZONE := Rect2(50, 46, 38, 18)
const RELIC_LIBRARY_ZONE := Rect2(83, 94, 30, 8)
## The Bazaar's place on the overworld, in the sand at the bottom left (FAL-783 plan).
const BAZAAR_ZONE := Rect2(17, 90, 26, 14)
## True once overworld.png has the Bazaar painted in (FAL-791); until then a coded
## marker shows where it is.
const BAZAAR_PAINTED := false

## Where each place sits on the Functions island board (centre, in % of the board; the
## FAL-783 plan's table): the all-regions dungeon at the tower in the middle, the regions
## around it, the two most-examined by the landing on the south shore. Spots are keyed by
## region id, plus "all" and "relic".
const SPOTS := {
	"quadratics": Vector2(25, 85), "exp-log": Vector2(75, 86), "function-basics": Vector2(21, 66),
	"graphs-features": Vector2(79, 65), "lines": Vector2(21, 27), "rational": Vector2(79, 28),
	"composite-inverse": Vector2(25, 10), "transformations": Vector2(75, 10), "all": Vector2(50, 46),
	"relic": Vector2(12, 50),
}
## The jetty the player lands at: painted only, a dot on the coded look, not a button.
const LANDING := Vector2(50, 97)
## The coded landmark's glyph for each region, in place of a number. Only characters the
## title font has (no superscript letters, FAL-499); mark() falls back to initials.
const GLYPHS := {
	"quadratics": "x²", "exp-log": "log", "graphs-features": "(x,y)", "composite-inverse": "f(g)",
	"rational": "1/x", "function-basics": "f(x)", "lines": "mx+c", "transformations": "-f(x)",
	Dungeon.ALL: "ALL", "relic": "?",
}
const STATE_COLOR := {"locked": UiTheme.DIM, "open": UiTheme.TEAL, "cleared": UiTheme.SAND}

var save_path := SaveData.PATH
## Where the island's art is looked for; tests point it at fixtures.
var art_dir := ART_DIR
var save: Dictionary = {}
## "world", "island" or "region".
var screen := ""
var route: Dictionary = {}
## SPARK's pick on the island on screen: Progress.suggest(), {} when nothing is open.
var pick: Dictionary = {}
## True while the last pointer was a finger: a first tap on a place shows its card.
var touch := false
## The place whose card is showing, and the place a first tap lit (touch only).
var card_for: Button
var armed: Button

var world: Control
var world_board: Control
var island: Control
var island_board: Control
var region_view: Control
var region_backdrop: TextureRect
var region_margin: MarginContainer
var region_col: VBoxContainer
var region_gap: Control
var _headers: Array = []
## The region screen's side margin, from _fit().
var _side := 36.0
## Each board's fitted [position, scale], from _fit().
var _fitted := {}
var _tween: Tween
## True while the board zooms into a place: presses wait for the next layer.
var _zooming := false
## True while the first focus is set, so it doesn't show a card on its own.
var _quiet := false


func _ready() -> void:
	theme = UiTheme.make()
	save = SaveData.load_from(save_path)
	_build()
	resized.connect(_fit)
	MapLink.listen(get_tree())
	var r := MapLink.current
	if r.is_empty():
		var link := MapLink.address()
		r = MapLink.parse(link)
		# A junk link falls back to the world map; the address bar says so too.
		if link != "" and MapLink.to_hash(r) != "#" + link.trim_prefix("#"):
			MapLink.current = r
			MapLink._write(r, true)
	_fit()
	show_route(r)


## Shows a route ({"screen": "world"}, {"screen": "island", "island"} or {"screen":
## "region", "island", "region"}) without touching the address bar. MapLink.go() is the
## way to move and record history. Moving down a layer fades the new one in; moving up
## zooms its board out of the place just left.
func show_route(r: Dictionary) -> void:
	var was := route
	route = r.duplicate()
	screen = route.get("screen", "world")
	MapLink.current = route.duplicate()
	if _tween != null:
		_tween.kill()
	_zooming = false
	card_for = null
	armed = null
	for layer in [world, island, region_view]:
		layer.modulate.a = 1.0
	world.visible = screen == "world"
	island.visible = screen == "island"
	region_view.visible = screen == "region"
	_fit()
	match screen:
		"world":
			_fill_world()
			Audio.play_location("overworld")
		"island":
			_fill_island()
			Audio.play_location(island_info(route.island).music)
		"region":
			_fill_region()
			Audio.play_location(island_info(route.island).music)
	var from := String(was.get("screen", ""))
	if from == "" or from == screen or reduced_motion():
		return
	var layer: Control = {"world": world, "island": island, "region": region_view}[screen]
	var out := (from == "island" and screen == "world") or (from == "region" and screen == "island")
	_tween = create_tween().set_parallel()
	if out:
		var board := world_board if screen == "world" else island_board
		var at := _island_point(String(was.get("island", ""))) if screen == "world" else _spot_point(String(was.get("region", "")))
		var fit: Array = _fitted[board]
		var z := _zoomed(board, at)
		board.position = z[0]
		board.scale = z[1]
		_tween.tween_property(board, "position", fit[0], ZOOM_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_tween.tween_property(board, "scale", fit[1], ZOOM_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	layer.modulate.a = 0.0
	_tween.tween_property(layer, "modulate:a", 1.0, FADE_TIME)


func go(r: Dictionary) -> void:
	MapLink.go(get_tree(), r)


## True when the game should cut instead of zooming: the save's reduced-motion setting,
## or the browser's prefers-reduced-motion on the web.
func reduced_motion() -> bool:
	if bool(save.get("settings", {}).get("reduced_motion", false)):
		return true
	if OS.has_feature("web"):
		return JavaScriptBridge.eval("window.matchMedia('(prefers-reduced-motion: reduce)').matches", true) == true
	return false


static func island_info(id: String) -> Dictionary:
	for i in ISLANDS:
		if i.id == id:
			return i
	return ISLANDS[1]


static func island_open(id: String) -> bool:
	return MapLink.OPEN_ISLANDS.has(id)


## The Thunderdome mixes every island, so it waits for a second one.
static func thunderdome_open() -> bool:
	return MapLink.OPEN_ISLANDS.size() >= 2


## "locked" (coming soon: nothing built), "open" or "cleared", for a region or "all".
func spot_state(region: String) -> String:
	if not Progress.is_built(region, Courses.of(save)):
		return "locked"
	return "cleared" if Progress.is_cleared(save, region) else "open"


## True when a run can start in the region: it has a built type.
static func can_start(region: String, course: String = "") -> bool:
	return Progress.is_built(region, course)


## The short mark on a spot's coded landmark: its glyph when the title font can draw
## every character of it, otherwise the initials of its name.
static func mark(id: String, glyph: String = "") -> String:
	if glyph == "":
		glyph = GLYPHS.get(id, "")
	if glyph != "" and range(glyph.length()).all(func(i): return UiTheme.TITLE_FONT.has_char(glyph.unicode_at(i))):
		return glyph
	var initials := ""
	for w in Dungeon.region_name(id).split(" ", false):
		if w != "and":
			initials += w.left(1).to_upper()
	return initials


## The island painting in art_dir (WebP first, then PNG), or "" for the coded look.
func background_path() -> String:
	for ext in ArtSlots.EXTENSIONS:
		var path := "%sbackground.%s" % [art_dir, ext]
		if ResourceLoader.exists(path):
			return path
	return ""


# ── Building ─────────────────────────────────────────────────

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = UiTheme.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	world = _layer("World")
	world_board = _board(world)
	var art := TextureRect.new()
	art.name = "Art"
	art.texture = OVERWORLD
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.size = BOARD
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world_board.add_child(art)
	_header(world, "The Wasteland", "Title", func(): MapLink.home(get_tree()))
	var scrap := UiTheme.label("", UiTheme.SMALL, UiTheme.SAND)
	scrap.name = "Scrap"
	scrap.autowrap_mode = TextServer.AUTOWRAP_OFF
	scrap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var row: Control = world.get_node("Header").get_child(0)
	row.add_child(scrap)
	row.move_child(scrap, row.get_node("HudGap").get_index())

	island = _layer("Island")
	island_board = _board(island)
	_header(island, "Signal Tower", "World map", func(): go(MapLink.WORLD))

	region_view = _layer("Region")
	region_backdrop = UiTheme.backdrop(REGION_WASH)
	region_view.add_child(region_backdrop)
	region_margin = MarginContainer.new()
	region_margin.name = "Margin"
	region_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	region_view.add_child(region_margin)
	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	region_margin.add_child(scroll)
	region_col = VBoxContainer.new()
	region_col.name = "Column"
	region_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	region_col.add_theme_constant_override("separation", 26)
	scroll.add_child(region_col)


func _layer(n: String) -> Control:
	var c := Control.new()
	c.name = n
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.clip_contents = true
	add_child(c)
	return c


func _board(parent: Control) -> Control:
	var b := Control.new()
	b.name = "Board"
	b.size = BOARD
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(b)
	return b


func _header(parent: Control, text: String, back_text: String, back: Callable) -> void:
	var m := MarginContainer.new()
	m.name = "Header"
	m.set_anchors_preset(Control.PRESET_TOP_WIDE)
	m.custom_minimum_size.y = HEADER
	parent.add_child(m)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 28)
	m.add_child(row)
	var b := Button.new()
	b.name = "Back"
	b.text = back_text
	b.add_theme_font_size_override("font_size", UiTheme.SMALL)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(back)
	row.add_child(b)
	var t := UiTheme.label(text, 84, UiTheme.TEAL)
	t.name = "Title"
	t.autowrap_mode = TextServer.AUTOWRAP_OFF
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.add_theme_font_override("font", UiTheme.TITLE_FONT)
	row.add_child(t)
	var gap := Control.new()
	gap.name = "HudGap"
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(gap)
	_headers.append(m)


## The course picker (FAL-397): one button per IB course, the save's course pressed.
## Picking one stores it and draws the screen again, so a region the course has no
## questions in turns to "Coming soon" and back. Every cell record stays.
func _course_row() -> Control:
	var row := HBoxContainer.new()
	row.name = "Course"
	row.add_theme_constant_override("separation", 12)
	var label := UiTheme.label("Course", UiTheme.SMALL, UiTheme.SAND)
	label.name = "Label"
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	row.add_child(label)
	var group := ButtonGroup.new()
	for id in Courses.ids():
		var b := Button.new()
		b.name = id
		b.text = Courses.info(id).short
		b.tooltip_text = Courses.info(id).name
		b.toggle_mode = true
		b.button_group = group
		b.set_pressed_no_signal(id == Courses.of(save))
		b.add_theme_font_size_override("font_size", UiTheme.SMALL)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(set_course.bind(id))
		row.add_child(b)
	return row


## Puts the save on a course, stores it and draws the region screen again (as the
## "Exam-style only" switch does). False for an id Courses doesn't list.
func set_course(id: String) -> bool:
	if not SaveData.set_course(save, id):
		return false
	SaveData.store(save, save_path)
	_fill_region()
	return true


## The Bazaar, as a history entry, so the browser's back button returns to the map.
func open_bazaar() -> void:
	go(MapLink.BAZAAR_ROUTE)


func _fit() -> void:
	var area := size
	var room := Rect2(0, HEADER, area.x, maxf(1.0, area.y - HEADER))
	for b in [world_board, island_board]:
		var s := minf(room.size.x / BOARD.x, room.size.y / BOARD.y)
		b.scale = Vector2(s, s)
		b.position = room.position + (room.size - BOARD * s) / 2.0
		_fitted[b] = [b.position, b.scale]
	var side := maxf(36.0, (area.x - (COLUMN_WIDE if area.x > area.y else COLUMN)) / 2.0)
	for m in _headers:
		m.add_theme_constant_override("margin_left", 36)
		m.add_theme_constant_override("margin_right", 0)
		m.add_theme_constant_override("margin_top", 30)
		(m.get_child(0).get_node("HudGap") as Control).custom_minimum_size.x = AudioHud.RESERVED_RIGHT
	_side = side
	if is_instance_valid(region_gap):
		region_gap.custom_minimum_size.x = maxf(0.0, AudioHud.RESERVED_RIGHT - side)
	region_margin.add_theme_constant_override("margin_left", int(side))
	region_margin.add_theme_constant_override("margin_right", int(side))
	region_margin.add_theme_constant_override("margin_top", 40)
	region_margin.add_theme_constant_override("margin_bottom", 30)


## A board's [position, scale] zoomed ZOOM times into a point (board units), the point
## in the middle of the room under the header.
func _zoomed(board: Control, at: Vector2) -> Array:
	var fit: Array = _fitted[board]
	var s: Vector2 = fit[1] * ZOOM
	var centre := Vector2(size.x / 2.0, HEADER + maxf(1.0, size.y - HEADER) / 2.0)
	return [centre - at * s, s]


static func _island_point(id: String) -> Vector2:
	var z: Rect2 = island_info(id).zone
	return z.position * BOARD / 100.0


static func _spot_point(id: String) -> Vector2:
	return SPOTS.get(id, Vector2(50, 50)) * BOARD / 100.0


## Goes to a route from a place on a board: zooms the board into the place first, unless
## motion is reduced. Presses during the zoom are ignored.
func zoom_to(board: Control, at: Vector2, then: Callable) -> void:
	if _zooming:
		return
	_hide_card()
	if reduced_motion():
		then.call()
		return
	_zooming = true
	var z := _zoomed(board, at)
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_parallel()
	_tween.tween_property(board, "position", z[0], ZOOM_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_tween.tween_property(board, "scale", z[1], ZOOM_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_tween.chain().tween_callback(func():
		_zooming = false
		then.call())


## A transparent button over a zone of a board (centre and size in % of the board).
func _zone_button(board: Control, n: String, zone: Rect2) -> Button:
	var b := Button.new()
	b.name = n
	b.flat = true
	b.size = Vector2(zone.size.x, zone.size.y) * BOARD / 100.0
	b.position = Vector2(zone.position.x, zone.position.y) * BOARD / 100.0 - b.size / 2.0
	board.add_child(b)
	return b


func _clear(c: Node, keep: int = 0) -> void:
	for i in range(c.get_child_count() - 1, keep - 1, -1):
		var ch := c.get_child(i)
		c.remove_child(ch)
		ch.queue_free()


## Sets the first focus without showing a card: nothing is named until the player looks.
func _first_focus(b: Button) -> void:
	if not is_instance_valid(b) or not b.is_inside_tree():
		return
	_quiet = true
	b.grab_focus(true)
	_quiet = false


# ── Places and their cards ───────────────────────────────────

## Makes a button a place: its card (name and line), its name for screen readers and
## tooltips, its light, and what going in does (`enter`, nothing for a closed place).
func _place(b: Button, title: String, line: String, color: Color, enter: Callable, tooltip: String = "") -> void:
	b.set_meta("card", [title, line, color])
	b.set_meta("enter", enter)
	b.tooltip_text = tooltip if tooltip != "" else "%s: %s" % [title, line]
	b.accessibility_name = "%s: %s" % [title, line]
	var glow := Glow.new()
	glow.name = "Glow"
	glow.size = b.size
	glow.round = b.size.x <= HIT + 1.0 and is_equal_approx(b.size.x, b.size.y)
	glow.visible = false
	b.add_child(glow)
	b.mouse_entered.connect(func(): show_card(b))
	b.mouse_exited.connect(func(): _let_go(b))
	b.focus_entered.connect(func():
		if not _quiet:
			show_card(b))
	b.focus_exited.connect(func(): _let_go(b))
	b.pressed.connect(press.bind(b))
	# A closed place has no press, but a tap still shows what it is.
	b.gui_input.connect(func(e: InputEvent):
		if b.disabled and (e is InputEventMouseButton or e is InputEventScreenTouch) and e.pressed:
			armed = b
			show_card(b))


## A press on a place: on a touch screen the first one shows its card, then the next
## one goes in. With a mouse or a keyboard it goes in at once.
func press(b: Button) -> void:
	if _zooming or b.disabled:
		return
	if touch and armed != b:
		armed = b
		show_card(b)
		return
	var enter: Callable = b.get_meta("enter")
	if enter.is_valid():
		enter.call()


## A press on the card goes into its place.
func press_card() -> void:
	if card_for != null and is_instance_valid(card_for) and not card_for.disabled:
		var enter: Callable = card_for.get_meta("enter")
		if enter.is_valid() and not _zooming:
			enter.call()


## Shows a place's card by it and lights the place.
func show_card(b: Button) -> void:
	var board := b.get_parent() as Control
	var card := board.get_node_or_null("Card") as Control
	if card == null:
		return
	if card_for != null and is_instance_valid(card_for) and card_for != b:
		(card_for.get_node("Glow") as Control).visible = false
	card_for = b
	(b.get_node("Glow") as Control).visible = true
	var info: Array = b.get_meta("card")
	(card.get_node("Box/Name") as Label).text = info[0]
	var line := card.get_node("Box/Line") as Label
	line.text = info[1]
	line.add_theme_color_override("font_color", info[2])
	card.visible = true
	card.reset_size()
	var r := Rect2(b.position, b.size)
	var gap := 14.0
	var y := r.position.y - card.size.y - gap
	if y < 0.0:
		y = r.end.y + gap
	if y + card.size.y > BOARD.y:
		y = r.get_center().y - card.size.y / 2.0
	var x := clampf(r.get_center().x - card.size.x / 2.0, 12.0, BOARD.x - card.size.x - 12.0)
	card.position = Vector2(x, clampf(y, 12.0, BOARD.y - card.size.y - 12.0))
	board.move_child(card, -1)


## The pointer or focus left a place: its card goes, unless the place still holds the
## pointer, the focus or a tap.
func _let_go(b: Button) -> void:
	if card_for != b or armed == b or b.is_hovered() or b.has_focus(true):
		return
	_hide_card()


func _hide_card() -> void:
	if card_for != null and is_instance_valid(card_for):
		(card_for.get_node("Glow") as Control).visible = false
		for board in [world_board, island_board]:
			var card := board.get_node_or_null("Card") as Control
			if card != null:
				card.visible = false
	card_for = null
	armed = null


## The card on a board: hidden until a place is hovered, focused or tapped. A press on
## it goes into the place.
func _card(board: Control) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "Card"
	card.visible = false
	var sb := UiTheme.panel(Color(0.08, 0.09, 0.12, 0.94))
	card.add_theme_stylebox_override("panel", sb)
	card.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
			press_card())
	var box := VBoxContainer.new()
	box.name = "Box"
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 0)
	card.add_child(box)
	var n := UiTheme.label("", 56, UiTheme.TEXT)
	n.name = "Name"
	n.autowrap_mode = TextServer.AUTOWRAP_OFF
	n.add_theme_font_override("font", UiTheme.TITLE_FONT)
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(n)
	var l := UiTheme.label("", UiTheme.SMALL, UiTheme.TEAL)
	l.name = "Line"
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(l)
	board.add_child(card)
	return card


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		touch = true
	elif event is InputEventKey or (event is InputEventMouse and event.device != InputEvent.DEVICE_ID_EMULATION):
		touch = false


## A tap or click on nothing puts the card away.
func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed and card_for != null:
		_hide_card()


## A place's light while its card shows: a ring round an island place, a frame round a
## world-map zone.
class Glow extends Control:
	var round := true

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := Color(UiTheme.TEXT, 0.85)
		if round:
			var r := size.x / 2.0
			draw_circle(size / 2.0, r - 6.0, Color(UiTheme.TEXT, 0.12))
			draw_arc(size / 2.0, r - 6.0, 0.0, TAU, 72, c, 8.0, true)
		else:
			draw_rect(Rect2(Vector2.ZERO, size).grow(-6.0), Color(UiTheme.TEXT, 0.1))
			draw_rect(Rect2(Vector2.ZERO, size).grow(-6.0), c, false, 8.0)


# ── The world map ────────────────────────────────────────────

func _fill_world() -> void:
	_clear(world_board, 1)
	var scrap := int(save.get("scrap", 0))
	(world.get_node("Header").get_child(0).get_node("Scrap") as Label).text = "Scrap: %d" % scrap
	for i in ISLANDS:
		var open := island_open(i.id)
		var b := _zone_button(world_board, "Island_" + i.id, i.zone)
		b.disabled = not open
		var to := {"screen": "island", "island": i.id}
		_place(b, i.name, i.topic if open else "Coming soon", UiTheme.TEAL if open else UiTheme.DIM,
			(func(): zoom_to(world_board, _island_point(i.id), go.bind(to))) if open else Callable(),
			"%s: %s" % [i.name, i.topic])
	var td := _zone_button(world_board, "Thunderdome", THUNDERDOME_ZONE)
	td.disabled = not thunderdome_open()
	_place(td, "Thunderdome", "Locked" if td.disabled else "Every island mixed", UiTheme.DIM if td.disabled else UiTheme.PINK,
		Callable(), "Thunderdome: opens with a second island" if td.disabled else "")
	var lib := _zone_button(world_board, "RelicLibrary", RELIC_LIBRARY_ZONE)
	lib.disabled = true
	_place(lib, "Relic Library", "Locked", UiTheme.DIM, Callable())
	var shop := _zone_button(world_board, "Bazaar", BAZAAR_ZONE)
	if not BAZAAR_PAINTED:
		var marker := Stall.new()
		marker.name = "Marker"
		marker.size = shop.size
		shop.add_child(marker)
	_place(shop, "Bazaar", "%d Scrap" % scrap, UiTheme.SAND,
		func(): zoom_to(world_board, Vector2(BAZAAR_ZONE.position.x, BAZAAR_ZONE.position.y) * BOARD / 100.0, open_bazaar),
		"Bazaar · %d Scrap" % scrap)
	_card(world_board)
	_first_focus.call_deferred(world_board.get_node("Island_functions") as Button)


# ── The Functions island ─────────────────────────────────────

func _fill_island() -> void:
	_clear(island_board)
	var info := island_info(route.island)
	var title := island.get_node("Header").get_child(0).get_node("Title") as Label
	title.text = info.name
	var bg_path := background_path()
	var painted := bg_path != ""
	if painted:
		var art := TextureRect.new()
		art.name = "Art"
		art.texture = load(bg_path)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_SCALE
		art.size = BOARD
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		island_board.add_child(art)
	else:
		island_board.add_child(_coded_ground())
	pick = Progress.suggest(save)
	var first: Button = null
	for id in MapLink.region_ids():
		var b := _spot(id, Dungeon.region_name(id), spot_state(id), painted)
		if first == null or id == pick.get("region"):
			first = b
	_spot(Dungeon.ALL, Dungeon.ALL_NAME, spot_state(Dungeon.ALL), painted)
	_spot("relic", "Relic device", "locked", painted)
	_card(island_board)
	_first_focus.call_deferred(first)


## The coded ground when there is no painting: a dusk gradient and the jetty as a dot.
func _coded_ground() -> Control:
	var g := TextureRect.new()
	g.name = "Ground"
	var grad := Gradient.new()
	grad.set_color(0, Color(0.24, 0.17, 0.2))
	grad.set_color(1, Color(0.36, 0.27, 0.16))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	g.texture = tex
	g.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	g.stretch_mode = TextureRect.STRETCH_SCALE
	g.size = BOARD
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var jetty := Jetty.new()
	jetty.name = "Jetty"
	jetty.size = BOARD
	g.add_child(jetty)
	return g


class Jetty extends Control:
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		draw_circle(LANDING * BOARD / 100.0, 22.0, Color(UiTheme.SAND, 0.6))


## A place on the island: a square button round its point with its landmark art for its
## state, nothing over a painting (with a state chip: a padlock or a flag) or the coded
## ring, and SPARK's beacon when it is the pick. Every spot but the Relic device opens
## its region screen; the Relic device is small and locked.
func _spot(id: String, title: String, state: String, painted: bool = false) -> Button:
	var at := _spot_point(id)
	var relic := id == "relic"
	var d := RELIC_HIT if relic else HIT
	var b := Button.new()
	b.name = "Spot_" + id
	b.flat = true
	b.size = Vector2(d, d)
	b.position = at - b.size / 2.0
	var look := _landmark(id, state, d, painted)
	if look != null:
		b.add_child(look)
	elif state != "open":
		if state == "locked":
			var wash := Wash.new()
			wash.name = "Wash"
			wash.size = b.size
			b.add_child(wash)
		var chip := Chip.new()
		chip.name = "Padlock" if state == "locked" else "Flag"
		chip.kind = state
		chip.position = Vector2(d / 2.0 - Chip.R, d - 2.0 * Chip.R - 6.0)
		b.add_child(chip)
	if id == pick.get("region"):
		var beacon := Beacon.new()
		beacon.name = "Beacon"
		beacon.r = d * 0.5 - 8.0
		beacon.position = b.size / 2.0
		b.add_child(beacon)
	island_board.add_child(b)
	if relic:
		b.disabled = true
		_place(b, title, "Locked", UiTheme.DIM, Callable(), "Locked · lessons later")
	else:
		var to := {"screen": "region", "island": route.island, "region": id}
		_place(b, title, spot_line(id, state), STATE_COLOR[state], func(): zoom_to(island_board, at, go.bind(to)))
	return b


static func _width(l: Label) -> float:
	var f := l.get_theme_font("font")
	return f.get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, l.get_theme_font_size("font_size")).x


## Takes a label's font size down until its text fits the width.
static func _shrink_to(l: Label, width: float) -> void:
	var fs := l.get_theme_font_size("font_size")
	while fs > UiTheme.SMALL and _width(l) > width:
		fs -= 2
		l.add_theme_font_size_override("font_size", fs)


## The line on a spot's card: "Coming soon", or how the player is doing there, and
## " · SPARK's pick" on the pick.
func spot_line(id: String, state: String) -> String:
	if state == "locked":
		return "Coming soon"
	var pick_tag := " · SPARK's pick" if id == pick.get("region") else ""
	var acc := Progress.accuracy(save, id)
	var best := Progress.best_floor(save, id)
	if acc.seen == 0 and best == 0:
		return "Not tried yet" + pick_tag
	var bits: Array = []
	if best > 0:
		bits.append("Floor %d" % best)
	if acc.seen > 0:
		bits.append("%d%%" % acc.percent)
	if state == "cleared":
		bits.append("Cleared")
	return " · ".join(bits) + pick_tag


## The look of a spot in a state, filling its square: its landmark art, nothing when the
## place is painted into the island (null), or the coded ring in the state's colour with
## the region's glyph (mark()).
func _landmark(id: String, state: String, box: float, painted: bool) -> Control:
	var path := "%s%s-%s.png" % [art_dir, id, state]
	var has_art := ResourceLoader.exists(path)
	if painted and not has_art:
		return null
	var holder := CenterContainer.new()
	holder.name = "Landmark"
	holder.size = Vector2(box, box)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if has_art:
		var art := TextureRect.new()
		art.name = "Art"
		art.texture = load(path)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.custom_minimum_size = Vector2(box, box)
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(art)
		return holder
	var border: Color = STATE_COLOR[state]
	if id == Dungeon.ALL and state != "locked":
		border = UiTheme.PINK
	var bg := UiTheme.PANEL if state != "locked" else Color(0.1, 0.12, 0.16, 0.85)
	holder.add_child(_ring(mark(id), box * (1.0 if id == Dungeon.ALL else 0.8), border, bg))
	return holder


## A coded ring, d across, with a short mark in it.
func _ring(text: String, d: float, border: Color, bg: Color) -> Control:
	var ring := PanelContainer.new()
	ring.name = "Coded"
	ring.custom_minimum_size = Vector2(d, d)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(10)
	sb.set_corner_radius_all(int(d / 2.0))
	ring.add_theme_stylebox_override("panel", sb)
	var l := UiTheme.label(text, 96 if text.length() == 1 else 72, border)
	l.name = "Mark"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.add_theme_font_override("font", UiTheme.TITLE_FONT)
	_shrink_to(l, d * 0.75)
	ring.add_child(l)
	return ring


## The Bazaar's coded marker until the overworld has it painted in: a ring like the
## island's, with a striped awning over a counter in it.
class Stall extends Control:
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size / 2.0
		var r := minf(size.x, size.y) * 0.4
		draw_circle(c, r, UiTheme.PANEL)
		draw_arc(c, r, 0.0, TAU, 64, UiTheme.SAND, 10.0, true)
		var w := r * 1.1
		var top := c.y - r * 0.45
		for i in 4:
			var x0 := c.x - w / 2.0 + w / 4.0 * i
			draw_colored_polygon(PackedVector2Array([Vector2(x0, top), Vector2(x0 + w / 4.0, top),
				Vector2(x0 + w / 4.0, top + r * 0.35), Vector2(x0, top + r * 0.35)]), UiTheme.PINK if i % 2 == 0 else UiTheme.SAND)
		draw_rect(Rect2(c.x - w / 2.0 + 8.0, top + r * 0.35, 10.0, r * 0.65), UiTheme.SAND)
		draw_rect(Rect2(c.x + w / 2.0 - 18.0, top + r * 0.35, 10.0, r * 0.65), UiTheme.SAND)
		draw_rect(Rect2(c.x - w / 2.0, c.y + r * 0.4, w, r * 0.2), UiTheme.SAND)


## The dark wash over a painted place that can't be played yet.
class Wash extends Control:
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		draw_circle(size / 2.0, size.x / 2.0 - 10.0, Color(0.03, 0.04, 0.06, 0.55))


## A state chip on a painted place, its top-left at its position: a padlock ("locked")
## or a flag ("cleared"), drawn so one painting serves every state.
class Chip extends Control:
	const R := 30.0
	var kind := "locked"

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size = Vector2(2.0 * R, 2.0 * R)

	func _draw() -> void:
		var c := Vector2(R, R)
		draw_circle(c, R, Color(0.05, 0.06, 0.09, 0.92))
		draw_arc(c, R - 2.0, 0.0, TAU, 40, UiTheme.SAND if kind == "cleared" else UiTheme.DIM, 4.0, true)
		if kind == "cleared":
			draw_line(c + Vector2(-9, 16), c + Vector2(-9, -16), UiTheme.TEXT, 4.0, true)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-7, -16), c + Vector2(14, -9), c + Vector2(-7, -2)]), UiTheme.SAND)
		else:
			draw_arc(c + Vector2(0, -4), 8.0, PI, TAU, 16, UiTheme.TEXT, 4.0, true)
			draw_rect(Rect2(c + Vector2(-12, -4), Vector2(24, 18)), UiTheme.TEXT)


## SPARK's beacon on the pick: two rings round the place and signal waves over it,
## pulsing. Drawn on top, so it shows over art too. Centred on its position.
class Beacon extends Control:
	var r := 140.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var t := create_tween().set_loops()
		t.tween_property(self, "modulate:a", 0.45, 0.9).set_trans(Tween.TRANS_SINE)
		t.tween_property(self, "modulate:a", 1.0, 0.9).set_trans(Tween.TRANS_SINE)

	func _draw() -> void:
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 64, UiTheme.PINK, 8.0, true)
		draw_arc(Vector2.ZERO, r + 18.0, 0.0, TAU, 64, Color(UiTheme.PINK, 0.4), 4.0, true)
		for i in 2:
			draw_arc(Vector2(0, -r - 12.0), 14.0 + 12.0 * i, PI * 1.2, PI * 1.8, 16, UiTheme.PINK, 6.0, true)


# ── The region screen ────────────────────────────────────────

func _fill_region() -> void:
	_clear(region_col)
	var id: String = route.region
	UiTheme.show_backdrop(region_backdrop, ArtSlots.backdrop(id))
	var head := HBoxContainer.new()
	head.name = "Head"
	head.add_theme_constant_override("separation", 24)
	var back := Button.new()
	back.name = "Back"
	back.text = "Island"
	back.add_theme_font_size_override("font_size", UiTheme.SMALL)
	back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func(): go({"screen": "island", "island": route.island}))
	head.add_child(back)
	var title := UiTheme.label(Dungeon.region_name(id), 84, UiTheme.TEAL)
	title.name = "Title"
	title.add_theme_font_override("font", UiTheme.TITLE_FONT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	region_gap = Control.new()
	region_gap.name = "HudGap"
	region_gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	region_gap.custom_minimum_size.x = maxf(0.0, AudioHud.RESERVED_RIGHT - _side)
	head.add_child(region_gap)
	region_col.add_child(head)
	region_col.add_child(_course_row())

	if not can_start(id, Courses.of(save)):
		var soon := UiTheme.label("Coming soon", 72, UiTheme.SAND)
		soon.name = "ComingSoon"
		soon.add_theme_font_override("font", UiTheme.TITLE_FONT)
		region_col.add_child(soon)
		var course := Courses.info(Courses.of(save))
		if can_start(id) and not course.is_empty():
			region_col.add_child(UiTheme.label("%s has no questions built here yet. Another course may: pick it above." % course.short, UiTheme.BODY, UiTheme.DIM))
		else:
			region_col.add_child(UiTheme.label("This region's questions aren't built yet. It opens here as soon as they are.", UiTheme.BODY, UiTheme.DIM))

	var exam := Button.new()
	exam.name = "ExamOnly"
	exam.toggle_mode = true
	exam.set_pressed_no_signal(bool(save.settings.get("exam_only", false)))
	exam.text = "Exam-style only: " + ("on" if exam.button_pressed else "off")
	exam.add_theme_font_size_override("font_size", UiTheme.SMALL)
	exam.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	exam.toggled.connect(func(on: bool):
		save.settings.exam_only = on
		SaveData.store(save, save_path)
		_fill_region())
	region_col.add_child(exam)

	region_col.add_child(_stats_panel(id))
	region_col.add_child(_weak_panel(id))

	if can_start(id, Courses.of(save)):
		var buttons := VBoxContainer.new()
		buttons.name = "Start"
		buttons.add_theme_constant_override("separation", 16)
		for f in Dungeon.start_floors(save, id):
			var b := Button.new()
			b.name = "Floor%d" % f
			b.text = "Start floor 1" if f == 1 else "Start at floor %d · floor %d boss beaten" % [f, f - 1]
			b.add_theme_font_size_override("font_size", UiTheme.BIG)
			b.custom_minimum_size.y = 120
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			b.pressed.connect(func(): start_run(id, f))
			buttons.add_child(b)
		var p := Button.new()
		p.name = "Practice"
		p.text = "Practice"
		p.add_theme_font_size_override("font_size", UiTheme.BIG)
		p.custom_minimum_size.y = 120
		p.alignment = HORIZONTAL_ALIGNMENT_LEFT
		p.pressed.connect(func(): open_practice(id))
		buttons.add_child(p)
		region_col.add_child(buttons)
		(buttons.get_child(0) as Button).grab_focus.call_deferred()
	else:
		back.grab_focus.call_deferred()


func _stats_panel(id: String) -> Control:
	var panel := PanelContainer.new()
	panel.name = "Stats"
	panel.add_theme_stylebox_override("panel", UiTheme.panel())
	var col := VBoxContainer.new()
	col.name = "Rows"
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)
	var acc := Progress.accuracy(save, id)
	var cov := Progress.coverage(save, id)
	var best := Progress.best_floor(save, id)
	var rows := [
		["Accuracy", "Accuracy: %d%% · %d of %d right" % [acc.percent, acc.right, acc.seen] if acc.seen > 0 else "Accuracy: no answers yet"],
		["BestFloor", "Best floor: %d" % best if best > 0 else "Best floor: no runs yet"],
		["Coverage", "Coverage: %d of %d checked" % [cov.checked, cov.total]],
	]
	for r in rows:
		var l := UiTheme.label(r[1], UiTheme.BIG, UiTheme.TEXT)
		l.name = r[0]
		col.add_child(l)
	return panel


func _weak_panel(id: String) -> Control:
	var col := VBoxContainer.new()
	col.name = "Weakest"
	col.add_theme_constant_override("separation", 10)
	col.add_child(UiTheme.label("Weakest skills", UiTheme.BIG, UiTheme.PINK))
	var weak := Progress.weakest_skills(save, id)
	if weak.is_empty():
		col.add_child(UiTheme.label("None yet: a skill shows here after %d answers." % Progress.MIN_ATTEMPTS, UiTheme.BODY, UiTheme.DIM))
	for w in weak:
		var l := UiTheme.label("• %s · %d%% of %d" % [w.name, w.percent, w.seen], UiTheme.BODY)
		l.name = "Skill_" + String(w.id).replace(".", "_")
		col.add_child(l)
	return col


## Starts a run in the region on a floor the save may start on. A region with nothing
## built can't start one.
func start_run(region: String, on_floor: int) -> bool:
	if not can_start(region, Courses.of(save)):
		return false
	preload("res://ui/fight.gd").launch = {"region": region, "floor": on_floor}
	get_tree().change_scene_to_file(FIGHT)
	return true


func open_practice(region: String) -> bool:
	if not can_start(region, Courses.of(save)):
		return false
	preload("res://ui/practice.gd").launch_region = region
	get_tree().change_scene_to_file(PRACTICE)
	return true
