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
## - The Functions island is a hub (FAL-531 plan): the all-regions dungeon at the tower in
##   the middle, the 8 regions around it, a spoke road from the tower to each and a loop
##   road between neighbours, so any region can be played in any order. A locked spot
##   waits for a Relic device. A region with no built type is "coming soon", worked out
##   from the engine, so a region lights up when its situations merge. SPARK's pick
##   (Progress.suggest()) gets a beacon and first focus: a suggestion, never a gate.
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
## A landmark's box on the island board, in board units, and the Relic device's.
const LANDMARK := 200.0
const RELIC_LANDMARK := 140.0
## A spot's button on the island board, and the Relic device's width.
const SPOT_SIZE := Vector2(480, LANDMARK + 110)
const RELIC_WIDTH := 200.0

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

## Where each landmark sits on the Functions island board (centre, in % of the board;
## the FAL-531 plan's table): the all-regions dungeon at the tower in the middle, the
## regions around it, the two most-examined by the landing on the south shore. Spots are
## keyed by region id, plus "all" and "relic".
const SPOTS := {
	"quadratics": Vector2(25, 85), "exp-log": Vector2(75, 86), "function-basics": Vector2(21, 66),
	"graphs-features": Vector2(79, 65), "lines": Vector2(21, 27), "rational": Vector2(79, 28),
	"composite-inverse": Vector2(25, 8), "transformations": Vector2(75, 9), "all": Vector2(50, 46),
	"relic": Vector2(12, 50),
}
## The jetty the player lands at (painted only, not a button), with a road to the tower.
const LANDING := Vector2(50, 97)
## The loop road around the island, between neighbouring regions.
const LOOP := [
	["quadratics", "exp-log"], ["exp-log", "graphs-features"], ["graphs-features", "rational"],
	["rational", "transformations"], ["transformations", "composite-inverse"],
	["composite-inverse", "lines"], ["lines", "function-basics"], ["function-basics", "quadratics"],
]
## The coded landmark's glyph for each region, in place of a number. Only characters the
## title font has (no superscript letters, FAL-499); mark() falls back to initials.
const GLYPHS := {
	"quadratics": "x²", "exp-log": "log", "graphs-features": "(x,y)", "composite-inverse": "f(g)",
	"rational": "1/x", "function-basics": "f(x)", "lines": "mx+c", "transformations": "-f(x)",
	Dungeon.ALL: "ALL", "relic": "?",
}

var save_path := SaveData.PATH
## Where the island's art is looked for; tests point it at fixtures.
var art_dir := ART_DIR
var save: Dictionary = {}
## "world", "island" or "region".
var screen := ""
var route: Dictionary = {}
## SPARK's pick on the island on screen: Progress.suggest(), {} when nothing is open.
var pick: Dictionary = {}

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
	if not Progress.is_built(region):
		return "locked"
	return "cleared" if Progress.is_cleared(save, region) else "open"


## True when a run can start in the region: it has a built type.
static func can_start(region: String) -> bool:
	return Progress.is_built(region)


## The roads on the island, as pairs of ends (a spot id or "landing"): a spoke from the
## tower to every other spot, the loop between neighbours and the road up from the landing.
static func roads() -> Array:
	var out: Array = [["landing", Dungeon.ALL]]
	for id in SPOTS:
		if id != Dungeon.ALL:
			out.append([Dungeon.ALL, id])
	return out + LOOP


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
	var bg_path := art_dir + "background.png"
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
	pick = Progress.suggest(save)
	var first: Button = null
	for id in MapLink.region_ids():
		var b := _spot(id, Dungeon.region_name(id), spot_state(id))
		if first == null or id == pick.get("region"):
			first = b
	_spot(Dungeon.ALL, Dungeon.ALL_NAME, spot_state(Dungeon.ALL))
	var relic := _spot("relic", "Relic device", "locked")
	relic.disabled = true
	relic.tooltip_text = "Locked · lessons later"
	first.grab_focus.call_deferred()


## The coded ground when there is no background art: a dusk gradient and the roads.
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
	var r := Roads.new()
	r.name = "Roads"
	r.size = BOARD
	for ends in roads():
		r.lines.append([_road_end(ends[0]), _road_end(ends[1]), ends.has(Dungeon.ALL)])
	g.add_child(r)
	return g


static func _road_end(id: String) -> Vector2:
	return (LANDING if id == "landing" else SPOTS[id]) * BOARD / 100.0


## The coded roads: spokes and the landing road dashed, the loop road fainter, and the
## jetty as a dot.
class Roads extends Control:
	## [from, to, spoke], in board units.
	var lines: Array = []

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		for l in lines:
			draw_dashed_line(l[0], l[1], Color(UiTheme.SAND, 0.5 if l[2] else 0.3), 10.0, 30.0)
		draw_circle(LANDING * BOARD / 100.0, 22.0, Color(UiTheme.SAND, 0.6))


## A spot on the island: its landmark (art for its state, or the coded look), name and
## state line, and SPARK's beacon when it is the pick. Every spot but the Relic device
## opens its region screen; the Relic device is small and shows its name only.
func _spot(id: String, title: String, state: String) -> Button:
	var at: Vector2 = SPOTS.get(id, Vector2(50, 50)) * BOARD / 100.0
	var relic := id == "relic"
	var box_h := RELIC_LANDMARK if relic else LANDMARK
	var b := Button.new()
	b.name = "Spot_" + id
	b.flat = true
	# As wide as SPOT_SIZE allows while staying centred on the spot and on the board.
	var w := RELIC_WIDTH if relic else minf(SPOT_SIZE.x, 2.0 * minf(at.x, BOARD.x - at.x))
	b.size = Vector2(w, box_h + 60) if relic else Vector2(w, SPOT_SIZE.y)
	b.position = at - Vector2(w / 2.0, box_h / 2.0)
	var box := VBoxContainer.new()
	box.name = "Box"
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 2)
	box.size = b.size
	box.add_child(_landmark(id, state, box_h))
	var name_l := _tag(title, UiTheme.SMALL if relic else 40, UiTheme.TEXT)
	name_l.name = "Name"
	name_l.autowrap_mode = TextServer.AUTOWRAP_OFF
	_shrink_to(name_l, w)
	box.add_child(name_l)
	if not relic:
		var state_l := _tag(spot_line(id, state), UiTheme.SMALL, {"locked": UiTheme.DIM, "open": UiTheme.TEAL, "cleared": UiTheme.SAND}[state])
		state_l.name = "State"
		state_l.autowrap_mode = TextServer.AUTOWRAP_OFF
		# A line too wide for the spot breaks before its last part (SPARK's pick).
		var i := state_l.text.rfind(" · ")
		if i >= 0 and _width(state_l) > w:
			state_l.text = state_l.text.left(i) + "\n" + state_l.text.substr(i + 3)
		box.add_child(state_l)
	b.add_child(box)
	if id == pick.get("region"):
		var beacon := Beacon.new()
		beacon.name = "Beacon"
		beacon.position = Vector2(w / 2.0, box_h / 2.0)
		b.add_child(beacon)
	if not relic:
		b.pressed.connect(func(): go({"screen": "region", "island": route.island, "region": id}))
	island_board.add_child(b)
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


## The line under a spot: "Coming soon", or how the player is doing there, and
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


## The landmark art for a spot in a state, or the coded look: a ring in the state's
## colour with the region's glyph (mark()).
func _landmark(id: String, state: String, box: float = LANDMARK) -> Control:
	var path := "%s%s-%s.png" % [art_dir, id, state]
	var holder := CenterContainer.new()
	holder.name = "Landmark"
	holder.custom_minimum_size = Vector2(0, box)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(path):
		var art := TextureRect.new()
		art.name = "Art"
		art.texture = load(path)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.custom_minimum_size = Vector2(box, box)
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(art)
		return holder
	var ring := PanelContainer.new()
	ring.name = "Coded"
	var d := box * (1.0 if id == Dungeon.ALL else 0.8)
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
	var text := mark(id)
	var l := UiTheme.label(text, 96 if text.length() == 1 else 72, sb.border_color)
	l.name = "Mark"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", UiTheme.TITLE_FONT)
	_shrink_to(l, d * 0.75)
	ring.add_child(l)
	holder.add_child(ring)
	return holder


## SPARK's beacon on the pick: two rings round the landmark and signal waves over it,
## pulsing. Drawn on top, so it shows over landmark art too. Centred on its position.
class Beacon extends Control:
	const R := 108.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var t := create_tween().set_loops()
		t.tween_property(self, "modulate:a", 0.45, 0.9).set_trans(Tween.TRANS_SINE)
		t.tween_property(self, "modulate:a", 1.0, 0.9).set_trans(Tween.TRANS_SINE)

	func _draw() -> void:
		draw_arc(Vector2.ZERO, R, 0.0, TAU, 64, UiTheme.PINK, 8.0, true)
		draw_arc(Vector2.ZERO, R + 18.0, 0.0, TAU, 64, Color(UiTheme.PINK, 0.4), 4.0, true)
		for i in 2:
			draw_arc(Vector2(0, -R - 12.0), 14.0 + 12.0 * i, PI * 1.2, PI * 1.8, 16, UiTheme.PINK, 6.0, true)


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

	if not can_start(id):
		var soon := UiTheme.label("Coming soon", 72, UiTheme.SAND)
		soon.name = "ComingSoon"
		soon.add_theme_font_override("font", UiTheme.TITLE_FONT)
		region_col.add_child(soon)
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

	if can_start(id):
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
	if not can_start(region):
		return false
	preload("res://ui/fight.gd").launch = {"region": region, "floor": on_floor}
	get_tree().change_scene_to_file(FIGHT)
	return true


func open_practice(region: String) -> bool:
	if not can_start(region):
		return false
	preload("res://ui/practice.gd").launch_region = region
	get_tree().change_scene_to_file(PRACTICE)
	return true
