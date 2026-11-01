extends Control
## The map (G5, FAL-417; Q3 and Q11 on the FAL-274 plan): the world, then an island,
## then a region's screen, then its dungeon. One scene with three screens; show_route()
## switches between them, and MapLink keeps the address bar in step, so links such as
## /next/#functions/quadratics open a region and the browser's back button works.
##
## - The world map is the HTML game's overworld painting with a button over each island.
##   The Signal Tower (Functions) is open; the other four are "coming later". The
##   Thunderdome opens once a second island does, and the Relic Library (FAL-325) has a
##   locked spot. Under the painting, as in the HTML game, a button opens the Bazaar (G6,
##   ui/bazaar.gd) with the Scrap there is to spend.
## - The Functions island has the 8 regions in the plan's order, the all-regions dungeon
##   and a locked spot for a Relic device. A region with no built type is "coming soon",
##   worked out from the engine, so a region lights up when its situations merge.
## - The region screen shows accuracy, best floor, coverage and the 3 weakest skills
##   (Progress), and starts a run on floor 1 or after a beaten boss, or opens Practice.
##
## Island art by file name (FAL-362 batch 4): ART_DIR/background.png and a landmark per
## spot and state (ART_DIR/<spot>-<state>.png). Each one missing falls back to the coded
## look. Sizes and names are in game/README.md under "Map art".

const FIGHT := "res://scenes/fight.tscn"
const PRACTICE := "res://scenes/practice.tscn"
const MAIN := "res://scenes/main.tscn"
const OVERWORLD := preload("res://assets/map/overworld.png")
const ART_DIR := "res://assets/map/functions/"
## Both maps are drawn on a portrait board of this size, scaled to fit under the header.
const BOARD := Vector2(1080, 1920)
const HEADER := 190.0
## The world map's bar under the board, for the Bazaar.
const FOOTER := 170.0
const COLUMN := 1000
const COLUMN_WIDE := 1500
## A landmark's box on the island board, in board units.
const LANDMARK := 200.0

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

## Where each spot sits on the Functions island board (centre, in % of the board): the
## regions climb from the bottom in the plan's order to the all-regions dungeon at the
## tower. Spots are keyed by region id, plus "all" and "relic".
const SPOTS := {
	"quadratics": Vector2(25, 86), "exp-log": Vector2(75, 78), "graphs-features": Vector2(25, 70),
	"composite-inverse": Vector2(75, 62), "rational": Vector2(25, 54), "function-basics": Vector2(75, 46),
	"lines": Vector2(25, 38), "transformations": Vector2(75, 30), "all": Vector2(68, 11),
	"relic": Vector2(23, 18),
}

var save_path := SaveData.PATH
var save: Dictionary = {}
## "world", "island" or "region".
var screen := ""
var route: Dictionary = {}

var world: Control
var world_board: Control
var bazaar_button: Button
var island: Control
var island_board: Control
var region_view: Control
var region_margin: MarginContainer
var region_col: VBoxContainer
var region_gap: Control
var _headers: Array = []
## The region screen's side margin, from _fit().
var _side := 36.0


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
## way to move and record history.
func show_route(r: Dictionary) -> void:
	route = r.duplicate()
	screen = route.get("screen", "world")
	MapLink.current = route.duplicate()
	world.visible = screen == "world"
	island.visible = screen == "island"
	region_view.visible = screen == "region"
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


func go(r: Dictionary) -> void:
	MapLink.go(get_tree(), r)


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
	_footer(world)

	island = _layer("Island")
	island_board = _board(island)
	_header(island, "Signal Tower", "World map", func(): go(MapLink.WORLD))

	region_view = _layer("Region")
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


## The world map's bottom bar: the Bazaar button.
func _footer(parent: Control) -> void:
	var m := MarginContainer.new()
	m.name = "Footer"
	m.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	m.grow_vertical = Control.GROW_DIRECTION_BEGIN
	m.custom_minimum_size.y = FOOTER
	m.add_theme_constant_override("margin_left", 36)
	m.add_theme_constant_override("margin_right", 36)
	m.add_theme_constant_override("margin_bottom", 30)
	parent.add_child(m)
	bazaar_button = Button.new()
	bazaar_button.name = "Bazaar"
	bazaar_button.add_theme_font_size_override("font_size", UiTheme.BIG)
	bazaar_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bazaar_button.custom_minimum_size.x = 640
	bazaar_button.pressed.connect(open_bazaar)
	m.add_child(bazaar_button)


## The Bazaar, as a history entry, so the browser's back button returns to the map.
func open_bazaar() -> void:
	go(MapLink.BAZAAR_ROUTE)


func _fit() -> void:
	var area := size
	var room := Rect2(0, HEADER, area.x, maxf(1.0, area.y - HEADER))
	var world_room := Rect2(room.position, Vector2(room.size.x, maxf(1.0, room.size.y - FOOTER)))
	for pair in [[world_board, world_room], [island_board, room]]:
		var b: Control = pair[0]
		var r: Rect2 = pair[1]
		var s := minf(r.size.x / BOARD.x, r.size.y / BOARD.y)
		b.scale = Vector2(s, s)
		b.position = r.position + (r.size - BOARD * s) / 2.0
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


## A board label: readable over painted art.
func _tag(text: String, size_: int, color: Color) -> Label:
	var l := UiTheme.label(text, size_, color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.06, 0.09))
	l.add_theme_constant_override("outline_size", 14)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


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


# ── The world map ────────────────────────────────────────────

func _fill_world() -> void:
	_clear(world_board, 1)
	for i in ISLANDS:
		var open := island_open(i.id)
		var b := _zone_button(world_board, "Island_" + i.id, i.zone)
		b.disabled = not open
		b.tooltip_text = "%s: %s" % [i.name, i.topic]
		_zone_label(b, i.name, i.topic if open else "Coming later", UiTheme.TEAL if open else UiTheme.DIM)
		if open:
			b.pressed.connect(func(): go({"screen": "island", "island": i.id}))
	var td := _zone_button(world_board, "Thunderdome", THUNDERDOME_ZONE)
	td.disabled = not thunderdome_open()
	_zone_label(td, "Thunderdome", "Opens with a second island" if td.disabled else "Every island mixed", UiTheme.PINK if not td.disabled else UiTheme.DIM)
	var lib := _zone_button(world_board, "RelicLibrary", RELIC_LIBRARY_ZONE)
	lib.disabled = true
	_zone_label(lib, "Relic Library", "Locked", UiTheme.DIM)
	bazaar_button.text = "Bazaar · %d Scrap" % int(save.get("scrap", 0))
	var first := world_board.get_node("Island_functions") as Button
	first.grab_focus.call_deferred()


func _zone_label(b: Button, n: String, sub: String, color: Color) -> void:
	var box := VBoxContainer.new()
	box.name = "Label"
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 0)
	box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var name_l := _tag(n, 60, UiTheme.TEXT if not b.disabled else UiTheme.SAND)
	name_l.name = "Name"
	name_l.add_theme_font_override("font", UiTheme.TITLE_FONT)
	name_l.autowrap_mode = TextServer.AUTOWRAP_OFF
	box.add_child(name_l)
	var sub_l := _tag(sub, UiTheme.SMALL, color)
	sub_l.name = "State"
	sub_l.autowrap_mode = TextServer.AUTOWRAP_OFF
	box.add_child(sub_l)
	b.add_child(box)


# ── The Functions island ─────────────────────────────────────

func _fill_island() -> void:
	_clear(island_board)
	var info := island_info(route.island)
	var title := island.get_node("Header").get_child(0).get_node("Title") as Label
	title.text = info.name
	var bg_path := ART_DIR + "background.png"
	if ResourceLoader.exists(bg_path):
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
	var first: Button = null
	for id in MapLink.region_ids():
		var b := _spot(id, Dungeon.region_name(id), spot_state(id), str(MapLink.region_ids().find(id) + 1))
		if first == null:
			first = b
	_spot(Dungeon.ALL, Dungeon.ALL_NAME, spot_state(Dungeon.ALL), "ALL")
	var relic := _spot("relic", "Relic device", "locked", "?")
	relic.disabled = true
	(relic.get_node("Box/State") as Label).text = "Locked · lessons later"
	first.grab_focus.call_deferred()


## The coded ground when there is no background art: a dusk gradient and a dashed trail
## through the spots in order.
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
	var trail := Trail.new()
	trail.size = BOARD
	for id in MapLink.region_ids() + [Dungeon.ALL]:
		if SPOTS.has(id):
			trail.points.append(SPOTS[id] * BOARD / 100.0)
	g.add_child(trail)
	return g


class Trail extends Control:
	var points := PackedVector2Array()

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		for i in points.size() - 1:
			draw_dashed_line(points[i], points[i + 1], Color(UiTheme.SAND, 0.5), 10.0, 30.0)


## A spot on the island: its landmark (art for its state, or the coded look), name and
## state line. Every spot but the Relic device opens its region screen.
func _spot(id: String, title: String, state: String, mark: String) -> Button:
	var at: Vector2 = SPOTS.get(id, Vector2(50, 50))
	var b := Button.new()
	b.name = "Spot_" + id
	b.flat = true
	b.size = Vector2(480, LANDMARK + 110)
	b.position = at * BOARD / 100.0 - Vector2(b.size.x / 2.0, LANDMARK / 2.0)
	var box := VBoxContainer.new()
	box.name = "Box"
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 2)
	box.size = b.size
	box.add_child(_landmark(id, state, mark))
	var name_l := _tag(title, 40, UiTheme.TEXT)
	name_l.name = "Name"
	name_l.autowrap_mode = TextServer.AUTOWRAP_OFF
	box.add_child(name_l)
	var state_l := _tag(spot_line(id, state), UiTheme.SMALL, {"locked": UiTheme.DIM, "open": UiTheme.TEAL, "cleared": UiTheme.SAND}[state])
	state_l.name = "State"
	state_l.autowrap_mode = TextServer.AUTOWRAP_OFF
	box.add_child(state_l)
	b.add_child(box)
	if id != "relic":
		b.pressed.connect(func(): go({"screen": "region", "island": route.island, "region": id}))
	island_board.add_child(b)
	return b


## The line under a spot: "Coming soon", or how the player is doing there.
func spot_line(id: String, state: String) -> String:
	if state == "locked":
		return "Coming soon"
	var acc := Progress.accuracy(save, id)
	var best := Progress.best_floor(save, id)
	if acc.seen == 0 and best == 0:
		return "Not tried yet"
	var bits: Array = []
	if best > 0:
		bits.append("Floor %d" % best)
	if acc.seen > 0:
		bits.append("%d%%" % acc.percent)
	if state == "cleared":
		bits.append("Cleared")
	return " · ".join(bits)


## The landmark art for a spot in a state, or the coded look: a ring in the state's
## colour with the region's number.
func _landmark(id: String, state: String, mark: String) -> Control:
	var path := "%s%s-%s.png" % [ART_DIR, id, state]
	var holder := CenterContainer.new()
	holder.name = "Landmark"
	holder.custom_minimum_size = Vector2(0, LANDMARK)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(path):
		var art := TextureRect.new()
		art.name = "Art"
		art.texture = load(path)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.custom_minimum_size = Vector2(LANDMARK, LANDMARK)
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(art)
		return holder
	var ring := PanelContainer.new()
	ring.name = "Coded"
	var d := LANDMARK * (1.0 if id == Dungeon.ALL else 0.8)
	ring.custom_minimum_size = Vector2(d, d)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = UiTheme.PANEL if state != "locked" else Color(0.1, 0.12, 0.16, 0.85)
	sb.border_color = {"locked": UiTheme.DIM, "open": UiTheme.TEAL, "cleared": UiTheme.SAND}[state]
	if id == Dungeon.ALL and state != "locked":
		sb.border_color = UiTheme.PINK
	sb.set_border_width_all(10)
	sb.set_corner_radius_all(int(d / 2.0))
	ring.add_theme_stylebox_override("panel", sb)
	var l := UiTheme.label(mark, 96 if mark.length() == 1 else 72, sb.border_color)
	l.name = "Mark"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", UiTheme.TITLE_FONT)
	ring.add_child(l)
	holder.add_child(ring)
	return holder


# ── The region screen ────────────────────────────────────────

func _fill_region() -> void:
	_clear(region_col)
	var id: String = route.region
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
