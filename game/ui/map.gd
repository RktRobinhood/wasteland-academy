extends Control
## The map (G5, FAL-417; Q3 and Q11 on the FAL-274 plan; the FAL-783 plan): the world,
## then an island, then a region's screen, then its dungeon. Each layer is a closer look
## at the place picked on the one above. One scene with three screens; show_route()
## switches between them, and MapLink keeps the address bar in step, so links such as
## /next/#functions/quadratics open a region and the browser's back button works.
##
## - The world map is the overworld painting (FAL-981, FAL-986) with an invisible button
##   over each place: the five islands, all open since FAL-925, the Thunderdome (every
##   island mixed, a region screen of its own at #thunderdome), the Relic Library (FAL-325,
##   optional worked examples) and the Bazaar (G6, ui/bazaar.gd). The painted landmarks
##   are the controls: no permanent dots, flags, padlocks or location marker. Its card
##   reveals status on hover, focus or tap. Last travel location stays in the save.
##   The header shows the Scrap there is to spend. Between the painting and the buttons,
##   the ambient layer (FAL-1075, ui/ambient_layer.gd, pieces in AMBIENT) plays a crow,
##   signal light, smoke, neon and dust; it takes no taps, and holds still with reduced motion.
## - An island is a hub (FAL-531 plan): its all-regions dungeon in the middle and its
##   regions (MapLink.region_ids(island)) around it, any of them in any order. No roads:
##   the places are fast-travel points. A locked spot waits for a Relic device. A region
##   with no built type is "coming soon", worked out from the engine, so a region lights
##   up when its situations merge. SPARK's pick (Progress.suggest() over the island's
##   regions) gets first focus and a note in its card: a suggestion, never a gate.
## - No persistent place names on either board. Hovering, focusing or tapping a
##   place shows its card: its name, then the topic, progress or availability.
##   With a mouse or keyboard a press goes in. On a touch screen the first tap shows the
##   card and lights the place, and a second tap on the place or the card goes in.
## - Going in zooms the board into the place (ZOOM_TIME), then the next layer fades in;
##   going back zooms out. With reduced motion (reduced_motion()) it cuts.
## - The region screen sits over the region's backdrop, with a fitted scrim so its text
##   keeps 4.5:1. It shows accuracy, best floor, coverage and the 3 weakest skills
##   (Progress), and starts a run on floor 1 or after a beaten boss, or opens Practice.
##
## Island art by file name (FAL-362 batch 4, FAL-783 plan), in each island's own folder,
## MAP_ART/<island>/ (FAL-925): background.webp or .png, one painting with every place
## painted in at its SPOTS point; then the buttons show a pin or a state chip
## (a dark wash and a padlock, or a flag). A landmark per spot and state
## (<spot>-<state>.png) still draws over it. With no painting the coded look draws the
## island's ground (ArtSlots.ground) and a ring per place, so a painting dropped into an
## island's folder later shows with no code change. Sizes and names are in game/README.md
## under "Map art".

const FIGHT := "res://scenes/fight.tscn"
const PRACTICE := "res://scenes/practice.tscn"
const MAIN := "res://scenes/main.tscn"
const OVERWORLD := preload("res://assets/map/overworld.png")
## The world board's moving pieces (FAL-1075), drawn by ui/ambient_layer.gd.
const AMBIENT := "res://data/ambient.json"
## Each island's art is in its own folder here: MAP_ART/<island id>/ (island_art_dir()).
const MAP_ART := "res://assets/map/"
## Logical portrait art and hit coordinate space, also used to anchor wide artwork.
const BOARD := Vector2(1080, 1920)
## Keep all hit/zoom coordinates in portrait art pixels. The wide islands share
## the portrait painting's middle square exactly in layout, at x −420, y +420.
const WIDE_FRAME := Rect2(-420, 420, 1920, 1080)
const WIDE_AT_RATIO := 1.15
const OVERWORLD_WIDE := "res://assets/map/overworld-wide.webp"
const WIDE_ART_LIMIT := 750_000
const WIDE_ART_KEYS := ["overworld", "algebra", "functions", "geometry", "stats", "calculus"]
## Authored W1-4 registration (assets/art/intake/world/zones.json). World wide
## has a different composition, so its gates cannot use the island transform.
const WIDE_WORLD := {
	"algebra": [Rect2(31.8, 19, 33.5, 22), Vector2(33, 25)],
	# Leave a narrow strip of open desert between the tower and Radio Spires.
	"functions": [Rect2(65.75, 19.5, 21, 23), Vector2(68, 26)],
	"geometry": [Rect2(19, 44.5, 32, 27), Vector2(18, 47)],
	"thunderdome": [Rect2(51, 42.5, 28, 25), Vector2(51, 51)],
	"stats": [Rect2(86.75, 42, 20, 30), Vector2(84, 53)],
	"bazaar": [Rect2(15.8, 74.5, 28.5, 27), Vector2(16, 78)],
	"calculus": [Rect2(49.8, 73, 35.5, 34), Vector2(50, 84)],
	"relic-library": [Rect2(83.5, 74.5, 26, 23), Vector2(85, 79)],
}

const HEADER := 190.0
## A header title's size, and the smallest it shrinks to on a narrow screen.
const TITLE_SIZE := 84
const TITLE_MIN := 40
const COLUMN := 1000
## A place's button on the island board, a square in board units round its point, and
## the Relic device's. A painted place fills about this square.
const HIT := 300.0
const RELIC_HIT := 160.0
## A place card's name size, and the least it shrinks to so the card fits beside its place;
## a side with less room than CARD_LEAST isn't tried.
const CARD_NAME := 56
const CARD_NAME_LEAST := 40
const CARD_LEAST := 300.0
## How far the board zooms into a place before the next layer shows, and how long the
## zoom and the fade take, in seconds.
const ZOOM := 2.6
const ZOOM_TIME := 0.4
const FADE_TIME := 0.25
## Base wash; the responsive scrim carries the stronger page contrast.
const REGION_WASH := 0.12

## The five islands, where each sits on the overworld (centre and size, in % of the
## board) and its pin (a point, in %), measured from the art on FAL-986 (zones.json). Where
## two landmarks overlap in the painting the zones are trimmed so no two buttons overlap,
## and each pin stays inside its own zone. js/router.js has the same zones. The id is the
## island's link (MapLink.OPEN_ISLANDS) and its art folder; its music is MapLink.MUSIC.
const ISLANDS := [
	{"id": "algebra", "name": "Scrap Fields", "topic": "Numbers and algebra", "zone": Rect2(21, 24, 38, 18), "pin": Vector2(22, 31)},
	{"id": "functions", "name": "Signal Tower", "topic": "Functions", "zone": Rect2(84.5, 24, 29, 18), "pin": Vector2(85, 28.5)},
	{"id": "geometry", "name": "Dry Flats", "topic": "Geometry and trigonometry", "zone": Rect2(16, 42.5, 32, 15), "pin": Vector2(14, 47)},
	{"id": "stats", "name": "Radio Spires", "topic": "Statistics and probability", "zone": Rect2(83, 41.5, 32, 17), "pin": Vector2(84, 47)},
	{"id": "calculus", "name": "Engine Core", "topic": "Calculus", "zone": Rect2(50.5, 57.75, 58, 15.5), "pin": Vector2(51, 64)},
]
const THUNDERDOME_ZONE := Rect2(50.5, 40.5, 31, 12)
const THUNDERDOME_PIN := Vector2(51, 46)
const RELIC_LIBRARY_ZONE := Rect2(77, 71, 38, 11)
const RELIC_LIBRARY_PIN := Vector2(80, 76)
## Optional worked lessons, independent from the locked playable Relic devices.
const RELIC_LIBRARY_LINE := "Watch a worked example or try a question"
## The Bazaar's place on the overworld, the caravan at the bottom left (FAL-986).
const BAZAAR_ZONE := Rect2(22, 70.75, 40, 10.5)
const BAZAAR_PIN := Vector2(25, 74)
## The line on a place's card after the first tap on a touch screen.
const TAP_AGAIN := "Tap again to go in"
## Where a new save stands on the world map (the save's "here").
const HOME := "bazaar"
## True once overworld.png has the Bazaar painted in (FAL-791, its junk caravan fills
## BAZAAR_ZONE); while false a coded marker shows where it is.
const BAZAAR_PAINTED := true

## Where each place sits on each island's board (centre, in % of the board): the
## all-regions dungeon in the middle, the regions round it, the two most-examined by the
## landing on the south shore, and the Relic device. Spots are keyed by island, then by
## region id, plus "all" (the island's all-regions dungeon, spot_key()) and "relic". The
## Signal Tower's (FAL-1614), the Dry Flats' (FAL-1034), the Radio Spires' (FAL-1611), the
## Engine Core's (FAL-1612) and the Scrap Fields' (FAL-1613) are measured from their paintings
## (zones.json in assets/art/intake/<island>/):
## each place's centre, nudged where two squares would overlap or one would leave the
## board.
const SPOTS := {
	"functions": {
		"quadratics": Vector2(20, 65.7), "exp-log": Vector2(78.6, 62.6), "function-basics": Vector2(15, 41.4),
		"graphs-features": Vector2(85, 43.8), "lines": Vector2(50, 25.8), "rational": Vector2(50, 68.8),
		"composite-inverse": Vector2(20, 25.5), "transformations": Vector2(81, 28), "all": Vector2(50.4, 49.1),
		"relic": Vector2(9.8, 53.6),
	},
	"algebra": {
		"sequences": Vector2(19, 61.8), "finance": Vector2(77, 64.9), "exponents-logs": Vector2(15, 33.7),
		"binomial": Vector2(83.5, 33.4), "proof": Vector2(50, 28), "all": Vector2(52, 49.1), "relic": Vector2(45.5, 71.9),
	},
	"geometry": {
		"triangles": Vector2(16.5, 61.8), "trig-graphs": Vector2(75, 61.5), "arcs-sectors": Vector2(14, 44.2),
		"geometry-3d": Vector2(86, 45.8), "trig-equations": Vector2(24, 28.1), "unit-circle": Vector2(79, 30),
		"all": Vector2(46.5, 49.7), "relic": Vector2(47.4, 71.6),
	},
	"stats": {
		"discrete-distributions": Vector2(18, 64.6), "probability": Vector2(81, 66.6), "normal-distribution": Vector2(15, 48.8),
		"regression": Vector2(84, 47.6), "conditional-probability": Vector2(17, 33), "averages-spread": Vector2(82, 31.9),
		"sampling-data": Vector2(45, 30.6), "all": Vector2(49, 55), "relic": Vector2(47.5, 71.2),
	},
	"calculus": {
		"kinematics": Vector2(22, 62.6), "stationary-points": Vector2(78, 62.6), "tangents-normals": Vector2(14, 46.8),
		"definite-integrals": Vector2(85, 46.9), "derivative-rules": Vector2(18, 31), "derivative-basics": Vector2(80, 31.2),
		"integration": Vector2(50, 28.6), "all": Vector2(50, 51.7), "relic": Vector2(48, 71.1),
	},
}
## The jetty the player lands at: painted only, a dot on the coded look, not a button.
const LANDING := Vector2(50, 97)
## The coded landmark's glyph for each region, in place of a number. Only characters the
## title font has (no superscript letters, FAL-499); mark() falls back to initials.
const GLYPHS := {
	"quadratics": "x²", "exp-log": "log", "graphs-features": "(x,y)", "composite-inverse": "f(g)",
	"rational": "1/x", "function-basics": "f(x)", "lines": "mx+c", "transformations": "-f(x)",
	"sequences": "1,3,5", "finance": "%", "exponents-logs": "10²", "binomial": "nCr", "proof": "QED",
	"triangles": "sin", "trig-graphs": "cos", "arcs-sectors": "rad", "geometry-3d": "3D", "trig-equations": "tan",
	"unit-circle": "30°", "discrete-distributions": "E(X)", "probability": "P(A)", "normal-distribution": "z",
	"regression": "r", "conditional-probability": "A|B", "averages-spread": "IQR", "sampling-data": "n=30",
	"kinematics": "v(t)", "stationary-points": "f'=0", "tangents-normals": "f'(a)", "definite-integrals": "[a,b]",
	"derivative-rules": "dy/dx", "derivative-basics": "f'(x)", "integration": "+C",
	"all": "ALL", "relic": "?",
}
const STATE_COLOR := {"locked": UiTheme.DIM, "open": UiTheme.TEAL, "cleared": UiTheme.SAND}

var save_path := SaveData.PATH
## Where the island's art is looked for, when set (tests point it at fixtures); "" for the
## island's own folder (island_art_dir()).
var art_dir := ""
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
var region_shade: TextureRect
var _region_wide := false
var _shades: Array[GradientTexture2D] = []
var region_margin: MarginContainer
var region_col: VBoxContainer
var region_gap: Control
var _headers: Array = []
## The region screen's side margin, from _fit().
var _side := 36.0
## Each board's fitted [position, scale], from _fit().
var _fitted := {}
var _map_frames := {}
var _wide_world := false
var _wide_island := false
static var _wide_cache := {}
var _wide_requests := {}
var _wide_failed := {}
var _wide_update_waiting := false
var _active_touch := {}
var _tween: Tween
var _return_zoom := false
## True while the board zooms into a place: presses wait for the next layer.
var _zooming := false
## True while the first focus is set, so it doesn't show a card on its own.
var _quiet := false


var scene_light := WorldLight.SceneGrade.new()
var _world_lights: Array[TextureRect] = []
var _world_ambient: AmbientLayer
var _light_elapsed := 0.0
var _zone_ambient: AmbientLayer

# One legend-free light per painted source, registered separately on portrait
# and landscape. The size is a native-art ellipse, not a marker or hit area.
# id, portrait position, landscape position, portrait spread, wide spread,
# source colour, max alpha, seconds of gentle breathing (0 = steady).
const WORLD_LIGHTS := [
	["Furnace", Vector2(551, 1196), Vector2(963, 837), Vector2(153, 105), Vector2(160, 120), Color(1, 0.58, 0.18), 0.66, 0.0],
	["LavaLeft", Vector2(459, 1201), Vector2(803, 948), Vector2(132, 37), Vector2(143, 52), Color(1, 0.37, 0.10), 0.65, 7.4],
	["LavaRight", Vector2(615, 1166), Vector2(1167, 840), Vector2(97, 51), Vector2(154, 68), Color(1, 0.41, 0.11), 0.54, 9.1],
	["ScrapGate", Vector2(248, 572), Vector2(640, 307), Vector2(95, 53), Vector2(151, 63), Color(1, 0.72, 0.31), 0.45, 0.0],
	["SignalBase", Vector2(922, 526), Vector2(1337, 266), Vector2(82, 75), Vector2(111, 108), Color(0.17, 0.77, 1), 0.45, 0.0],
	["RadioDoors", Vector2(898, 852), Vector2(1618, 574), Vector2(120, 93), Vector2(144, 111), Color(0.38, 0.40, 1), 0.53, 0.0],
	["BazaarLanterns", Vector2(234, 1352), Vector2(358, 842), Vector2(192, 63), Vector2(320, 82), Color(1, 0.69, 0.31), 0.45, 0.0],
]


func _update_world_light(delta: float) -> void:
	scene_light.advance(delta)
	for board in [world_board, island_board]:
		var art := board.get_node_or_null("Art") as TextureRect
		if art != null:
			art.self_modulate = scene_light.grade
	region_backdrop.self_modulate = scene_light.grade
	if is_instance_valid(_zone_ambient) and _zone_ambient.is_visible_in_tree():
		_zone_ambient.modulate = scene_light.grade
	if not world.is_visible_in_tree():
		return
	_light_elapsed += delta
	for i in _world_lights.size():
		var entry: Array = WORLD_LIGHTS[i]
		var period: float = entry[7]
		var pulse := 1.0
		if period > 0.0 and not _world_ambient.reduced_motion:
			pulse = 0.94 + 0.06 * sin(_light_elapsed * TAU / period + i)
		var colour: Color = entry[5]
		colour.a = float(entry[6]) * scene_light.local_light * pulse
		_world_lights[i].self_modulate = colour


func _process(delta: float) -> void:
	_update_world_light(delta)


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
	_update_world_light(0.0)
	if SaveData.needs_course(save):
		ask_course()


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
	_return_zoom = false
	card_for = null
	armed = null
	for layer in [world, island, region_view]:
		layer.modulate.a = 1.0
	world.visible = screen == "world"
	island.visible = screen == "island"
	region_view.visible = screen == "region"
	_fit(false)
	match screen:
		"world":
			_fill_world()
			Audio.play_location("overworld")
		"island":
			_fill_island()
			Audio.play_location(String(MapLink.MUSIC.get(route.island, "")))
		"region":
			_fill_region()
			Audio.play_location(MapLink.music_for(route.region))
	var from := String(was.get("screen", ""))
	if from == "" or from == screen or reduced_motion():
		return
	var layer: Control = {"world": world, "island": island, "region": region_view}[screen]
	var out := (from == "island" and screen == "world") or (from == "region" and screen == "island")
	_tween = create_tween().set_parallel()
	if out:
		_return_zoom = true
		var board := world_board if screen == "world" else island_board
		var at := _island_point(String(was.get("island", ""))) if screen == "world" else _spot_point(String(was.get("island", "")), String(was.get("region", "")))
		var fit: Array = _fitted[board]
		var z := _zoomed(board, at)
		board.position = z[0]
		board.scale = z[1]
		_tween.tween_property(board, "position", fit[0], ZOOM_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_tween.tween_property(board, "scale", fit[1], ZOOM_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	layer.modulate.a = 0.0
	_tween.tween_property(layer, "modulate:a", 1.0, FADE_TIME)
	_tween.finished.connect(func(): _return_zoom = false)


func go(r: Dictionary) -> void:
	MapLink.go(get_tree(), r)


## True when the game should cut instead of zooming: the save's reduced-motion setting,
## or the browser's prefers-reduced-motion on the web.
func reduced_motion() -> bool:
	return AmbientLayer.motion_reduced(save)


## Settings calls this when the student's motion preference changes on the map.
func apply_settings() -> void:
	var ambient := world_board.get_node("Ambient") as AmbientLayer
	var reduce := reduced_motion()
	if is_instance_valid(_zone_ambient):
		_zone_ambient.reduced_motion = reduce
	if ambient.reduced_motion != reduce:
		ambient.reduced_motion = reduce
		ambient.build(AmbientLayer.entries(AMBIENT, "map_wide" if _wide_world else "map"))


static func island_info(id: String) -> Dictionary:
	if id == Dungeon.THUNDERDOME:
		return {"id": id, "name": Dungeon.THUNDERDOME_NAME, "topic": "Questions from all over the Wasteland", "zone": THUNDERDOME_ZONE,
			"pin": THUNDERDOME_PIN}
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


## The folder the island on screen loads its art from: art_dir when a test set it, else
## MAP_ART/<island>/.
func island_art_dir() -> String:
	return art_dir if art_dir != "" else "%s%s/" % [MAP_ART, route.get("island", "functions")]


## What the region screen and the fight screen show behind a region: its backdrop, or,
## with none, a close-up of its island on the overworld painting (the Thunderdome's arena
## for the Thunderdome), so a region with no art yet still reads as its island, under the
## same wash (FAL-925).
static func backdrop_for(region: String) -> Texture2D:
	var art := ArtSlots.backdrop(region)
	if art != null:
		return art
	var zone: Rect2 = island_info(MapLink.island_of(region)).zone
	var tex := AtlasTexture.new()
	tex.atlas = OVERWORLD
	tex.region = Rect2((zone.position - zone.size / 2.0) * BOARD / 100.0, zone.size * BOARD / 100.0).intersection(
		Rect2(Vector2.ZERO, BOARD))
	return tex


## The island's painting (WebP first, then PNG), or "" for the coded look.
func background_path() -> String:
	for ext in ArtSlots.EXTENSIONS:
		var path := "%sbackground.%s" % [island_art_dir(), ext]
		if ResourceLoader.exists(path):
			return path
	return ""


func _island_wide_path() -> String:
	return "%sbackground-wide.webp" % island_art_dir()


## Texture and hotspot registration share the same board units. Crop portrait
## art through its atlas rather than stretching it or moving the controls.
func _frame_painting(board: Control) -> void:
	var art := board.get_node_or_null("Art") as TextureRect
	if art == null or not _map_frames.has(board):
		return
	var on_world := board == world_board
	var wide := _wide_world if on_world else _wide_island
	var frame: Rect2 = _map_frames[board]
	if wide:
		var id := "overworld" if on_world else String(route.island)
		art.texture = _wide_texture(id, OVERWORLD_WIDE if on_world else _island_wide_path(), false)
	else:
		var source: Texture2D = OVERWORLD if on_world else art.get_meta("portrait") as Texture2D
		if source == null:
			return
		if frame == Rect2(Vector2.ZERO, BOARD) or source.get_size() != BOARD:
			art.texture = source
		else:
			var crop := AtlasTexture.new()
			crop.atlas = source
			crop.region = frame
			crop.filter_clip = true
			art.texture = crop
	art.position = frame.position
	art.size = frame.size
	if on_world:
		var source_frame := WIDE_FRAME if wide else Rect2(Vector2.ZERO, BOARD)
		for i in _world_lights.size():
			var light := _world_lights[i]
			var entry: Array = WORLD_LIGHTS[i]
			var at: Vector2 = entry[2] if wide else entry[1]
			var spread: Vector2 = entry[4] if wide else entry[3]
			light.size = spread
			light.position = source_frame.position + at - frame.position - spread * 0.5
		var ambient := board.get_node("Ambient") as AmbientLayer
		var key := "map_wide" if wide else "map"
		if ambient.get_meta("layout", "map") != key:
			ambient.set_meta("layout", key)
			ambient.position = WIDE_FRAME.position if wide else Vector2.ZERO
			ambient.size = WIDE_FRAME.size if wide else BOARD
			ambient.build(AmbientLayer.entries(AMBIENT, key))


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
	var falloff := WorldLight.radial_falloff()
	var blend := CanvasItemMaterial.new()
	blend.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	for entry in WORLD_LIGHTS:
		var light := TextureRect.new()
		light.name = entry[0]
		light.mouse_filter = Control.MOUSE_FILTER_IGNORE
		light.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		light.texture = falloff
		light.material = blend
		light.self_modulate.a = 0.0
		art.add_child(light)
		_world_lights.append(light)
	# Over the painting, under the zone buttons and pins; it takes no taps.
	var ambient := AmbientLayer.new()
	ambient.name = "Ambient"
	ambient.size = BOARD
	ambient.reduced_motion = reduced_motion()
	world_board.add_child(ambient)
	_world_ambient = ambient
	ambient.build(AmbientLayer.entries(AMBIENT, "map"))
	_header(world, "The Wasteland", "◂ Title", func(): MapLink.home(get_tree()))
	var scrap := UiTheme.label("", UiTheme.SMALL, UiTheme.SAND)
	scrap.name = "Scrap"
	scrap.autowrap_mode = TextServer.AUTOWRAP_OFF
	scrap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var row: Control = world.get_node("Header").get_child(0)
	row.add_child(scrap)
	row.move_child(scrap, row.get_node("HudGap").get_index())

	island = _layer("Island")
	island_board = _board(island)
	_header(island, "Signal Tower", "◂ The Wasteland", func(): go(MapLink.WORLD))

	region_view = _layer("Region")
	region_backdrop = UiTheme.backdrop(REGION_WASH)
	region_view.add_child(region_backdrop)
	region_shade = TextureRect.new()
	region_shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	region_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	region_view.add_child(region_shade)
	region_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shades.assign([_region_scrim(false), _region_scrim(true)])
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
	var t := UiTheme.label(text, TITLE_SIZE, UiTheme.TEAL)
	t.name = "Title"
	t.autowrap_mode = TextServer.AUTOWRAP_OFF
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.add_theme_font_override("font", UiTheme.TITLE_FONT)
	# On a phone the title shrinks to fit rather than trimming ("THE WASTEL…", FAL-1608).
	t.resized.connect(fit_title.bind(t))
	row.add_child(t)
	var gap := Control.new()
	gap.name = "HudGap"
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(gap)
	_headers.append(m)


## The largest title size, up to TITLE_SIZE and no smaller than TITLE_MIN, at which a
## header title's text fits its label's width.
static func fit_title(t: Label) -> void:
	var font := t.get_theme_font("font")
	var s := TITLE_SIZE
	while s > TITLE_MIN and font.get_string_size(t.text, HORIZONTAL_ALIGNMENT_LEFT, -1, s).x > t.size.x:
		s -= 2
	if t.get_theme_font_size("font_size") != s:
		t.add_theme_font_size_override("font_size", s)


## The course picker (FAL-397): one button per IB course, the save's course pressed.
## Picking one stores it and draws the screen again, so a region the course has no
## questions in turns to "Coming soon" and back. Every cell record stays.
func _course_row() -> Control:
	var row := HBoxContainer.new()
	row.name = "Course"
	row.add_theme_constant_override("separation", 12)
	var label := UiTheme.label("Your course", UiTheme.SMALL, UiTheme.SAND)
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
	if screen == "region":
		_fill_region()
	return true


## The first-launch question (#186): a blank save is asked for its course once, over
## whatever screen opened. Picking one stores it.
func ask_course() -> FirstRun:
	var f := FirstRun.course_pick()
	f.finished.connect(set_course)
	add_child(f)
	return f


## The Bazaar, as a history entry, so the browser's back button returns to the map.
func open_bazaar() -> void:
	go(MapLink.BAZAAR_ROUTE)


## Fit wide artwork on landscape screens. Portrait keeps its entire width and
## crops only empty top/bottom strips when height would shrink its hotspots.
static func map_frame(room: Vector2, wide: bool, island_map: bool) -> Rect2:
	if wide:
		return WIDE_FRAME
	# Ensure all registered targets and surrounding interaction area remain in
	# frame even in a squat viewport with a missing/unregistered wide painting.
	var required: Rect2 = Rect2(0, 360, BOARD.x, 1230) if island_map else Rect2(0, 256, BOARD.x, 1312)
	var h := floorf(clampf(room.y / maxf(1.0, room.x) * BOARD.x, required.size.y, BOARD.y))
	var y := floorf(clampf(required.get_center().y - h / 2.0, 0.0, BOARD.y - h))
	return Rect2(0, y, BOARD.x, h)


func _fit(refresh_assets := true) -> void:
	# A returning board's tween ends at the old transform. If a window resize
	# or a landscape art upgrade changes that transform, settle at the new fit
	# rather than letting the old tween move the map and its hitboxes off-centre.
	if _return_zoom:
		_tween.kill()
		_return_zoom = false
		(world if screen == "world" else island).modulate.a = 1.0
	var area := size
	var room := Rect2(0, HEADER, area.x, maxf(1.0, area.y - HEADER))
	var had_frame := not _map_frames.is_empty()
	var was_wide_world := _wide_world
	var was_wide_island := _wide_island
	var landscape := room.size.x / room.size.y >= WIDE_AT_RATIO
	_wide_world = landscape and _wide_texture("overworld", OVERWORLD_WIDE, screen == "world") != null
	_wide_island = landscape and art_dir == "" and route.has("island") and _wide_texture(String(route.island), _island_wide_path(), screen == "island") != null
	for b in [world_board, island_board]:
		var island_map: bool = b == island_board
		var frame := map_frame(room.size, _wide_island if island_map else _wide_world, island_map)
		_map_frames[b] = frame
		var scaler := minf(room.size.x / frame.size.x, room.size.y / frame.size.y)
		b.scale = Vector2(scaler, scaler)
		var stage := room.position + (room.size - frame.size * scaler) / 2.0
		b.position = stage - frame.position * scaler
		_fitted[b] = [b.position, b.scale]
		if not island_map or screen == "island":
			_frame_painting(b)
	# Only switching the authored layout rebuilds the hit controls. A normal
	# resize keeps the current controls and exact input registrations.
	if refresh_assets and had_frame and screen == "world" and was_wide_world != _wide_world and world_board.has_node("Card"):
		_rebuild_framed_controls(world_board)
	elif refresh_assets and had_frame and screen == "island" and was_wide_island != _wide_island and island_board.has_node("Card"):
		_rebuild_framed_controls(island_board)
	for m in _headers:
		m.add_theme_constant_override("margin_left", 36)
		m.add_theme_constant_override("margin_right", 0)
		m.add_theme_constant_override("margin_top", 30)
		(m.get_child(0).get_node("HudGap") as Control).custom_minimum_size.x = AudioHud.RESERVED_RIGHT
	# Reserve most of the landscape for the region painting; on portrait keep
	# the readable vertically scrolling flow, with the action near the top.
	_region_wide = area.x >= 2100.0 and area.x / area.y >= 1.15
	_side = clampf(area.x * 0.052, 68.0, 164.0) if _region_wide else maxf(36.0, (area.x - COLUMN) / 2.0)
	var right := area.x - _side - clampf(area.x * 0.45, 1150.0, 1380.0) if _region_wide else _side
	if is_instance_valid(region_gap):
		region_gap.custom_minimum_size.x = _region_hud_gap()
	region_margin.add_theme_constant_override("margin_left", int(_side))
	region_margin.add_theme_constant_override("margin_right", int(right))
	region_margin.add_theme_constant_override("margin_top", 72 if _region_wide else 40)
	region_margin.add_theme_constant_override("margin_bottom", 30)
	region_shade.texture = _shades[int(_region_wide)]


func _region_hud_gap() -> float:
	return 0.0 if _region_wide else maxf(0.0, AudioHud.RESERVED_RIGHT - _side)


static func _region_scrim(wide: bool) -> GradientTexture2D:
	# Judgement and copy sit against the matte tint, while the unoccupied side
	# shows the region as a place, instead of shading the whole image equally.
	var stops := Gradient.new()
	stops.offsets = PackedFloat32Array([0.0, 0.61, 0.74, 1.0] if wide else [0.0, 0.36, 0.61, 1.0])
	var ink := Color(0.075, 0.092, 0.13)
	stops.colors = PackedColorArray([
		Color(ink, 0.94), Color(ink, 0.91), Color(ink, 0.26 if wide else 0.88), Color(ink, 0.09 if wide else 0.88),
	])
	var fade := GradientTexture2D.new()
	fade.gradient = stops
	fade.width = 256 if wide else 2
	fade.height = 2 if wide else 256
	fade.fill_to = Vector2(1.0, 0.0) if wide else Vector2(0.0, 1.0)
	return fade


## Preserve the selected destination and card when its responsive geometry changes.
func _rebuild_framed_controls(board: Control) -> void:
	var focus := board.get_viewport().gui_get_focus_owner()
	var focus_name := String(focus.name) if is_instance_valid(focus) and focus.get_parent() == board else ""
	var card_name := String(card_for.name) if is_instance_valid(card_for) and card_for.get_parent() == board else ""
	var armed_name := String(armed.name) if is_instance_valid(armed) and armed.get_parent() == board else ""
	armed = null
	card_for = null
	if board == world_board:
		_fill_world()
	else:
		_fill_island()
	if focus_name != "":
		_first_focus.call_deferred(board.get_node_or_null(focus_name) as Button)
	if armed_name != "":
		armed = board.get_node_or_null(armed_name) as Button
	if card_name != "":
		var prior := board.get_node_or_null(card_name) as Button
		if prior != null:
			show_card(prior)


## Portrait is always available. Web fetches only the landscape being opened.
func _wide_texture(key: String, path: String, request_if_missing: bool) -> Texture2D:
	if not WIDE_ART_KEYS.has(key):
		return null
	if not OS.has_feature("web"):
		return load(path) as Texture2D if ResourceLoader.exists(path) else null
	if _wide_cache.has(key):
		return _wide_cache[key]
	if request_if_missing and not _wide_failed.has(key) and not _wide_requests.has(key):
		_request_wide(key)
	return null


static func wide_web_path(key: String, build: String) -> String:
	return "map-art/%s/%s.webp" % [build.uri_encode(), key] if WIDE_ART_KEYS.has(key) else ""


func _request_wide(key: String) -> void:
	var path := wide_web_path(key, Build.id())
	var url = JavaScriptBridge.eval(
		"(() => { const u = new URL(%s, document.baseURI); return u.origin === new URL(document.URL).origin ? u.href : ''; })()" %
		JSON.stringify(path), true)
	if not url is String or url.is_empty():
		_wide_failed[key] = true
		return
	var request := HTTPRequest.new()
	request.body_size_limit = WIDE_ART_LIMIT
	request.timeout = 9.0
	request.max_redirects = 0
	request.accept_gzip = false
	add_child(request)
	_wide_requests[key] = request
	request.request_completed.connect(func(result: int, status: int, headers: PackedStringArray, body: PackedByteArray) -> void:
		_wide_requests.erase(key)
		request.queue_free()
		var image := read_wide_web_image(result, status, headers, body)
		if image == null:
			_wide_failed[key] = true
			return
		_wide_cache[key] = ImageTexture.create_from_image(image)
		_refresh_on_wide_load()
	)
	if request.request(url) != OK:
		_wide_requests.erase(key)
		request.queue_free()
		_wide_failed[key] = true


static func read_wide_web_image(result: int, status: int, headers: PackedStringArray, body: PackedByteArray) -> Image:
	if result != HTTPRequest.RESULT_SUCCESS or status != 200 or body.size() < 12 or body.size() > WIDE_ART_LIMIT:
		return null
	var webp := false
	for line in headers:
		var name := line.get_slice(":", 0).strip_edges().to_lower()
		if name == "content-type":
			webp = line.get_slice(":", 1).get_slice(";", 0).strip_edges().to_lower() == "image/webp"
	if not webp or body.slice(0, 4).get_string_from_ascii() != "RIFF" or body.slice(8, 12).get_string_from_ascii() != "WEBP":
		return null
	var image := Image.new()
	if image.load_webp_from_buffer(body) != OK or image.get_size() != Vector2i(WIDE_FRAME.size):
		return null
	return image


## Never move a target under an active press or an armed touchscreen card.
func _refresh_on_wide_load() -> void:
	if not is_inside_tree() or screen not in ["world", "island"]:
		return
	if _zooming or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or not _active_touch.is_empty() or (touch and is_instance_valid(armed)):
		if not _wide_update_waiting:
			_wide_update_waiting = true
			get_tree().create_timer(0.2).timeout.connect(func():
				_wide_update_waiting = false
				_refresh_on_wide_load())
		return
	_fit()


## A board's [position, scale] zoomed ZOOM times into a point (board units), the point
## in the middle of the room under the header.
func _zoomed(board: Control, at: Vector2) -> Array:
	var fit: Array = _fitted[board]
	var s: Vector2 = fit[1] * ZOOM
	var centre := Vector2(size.x / 2.0, HEADER + maxf(1.0, size.y - HEADER) / 2.0)
	return [centre - at * s, s]


## Convert a registered landscape percentage into the common art space.
static func wide_percent(p: Vector2) -> Vector2:
	return (WIDE_FRAME.position + p * WIDE_FRAME.size / 100.0) * 100.0 / BOARD


func _world_zone(id: String, portrait: Rect2) -> Rect2:
	if not _wide_world:
		return portrait
	var z: Rect2 = WIDE_WORLD[id][0]
	return Rect2(wide_percent(z.position), z.size * WIDE_FRAME.size / BOARD)


## The painted detail used to audit hotspot registration; no sprite is placed here.
func _world_landmark_anchor(id: String, portrait: Vector2) -> Vector2:
	return wide_percent(WIDE_WORLD[id][1]) if _wide_world else portrait


func _island_point(id: String) -> Vector2:
	# Only a real island links back this way. Direct routes keep their own ids.
	var info := island_info(id)
	var z: Rect2 = _world_zone(id, info.zone) if WIDE_WORLD.has(id) else info.zone
	return z.position * BOARD / 100.0


## A place's point on an island's board (board units).
static func _spot_point(island: String, id: String) -> Vector2:
	return (SPOTS.get(island, {}) as Dictionary).get(spot_key(id), Vector2(50, 50)) * BOARD / 100.0


## The key a place goes by on an island board (SPOTS, GLYPHS, its art and its node): its
## region id, or "all" for any island's all-regions dungeon.
static func spot_key(id: String) -> String:
	return Dungeon.ALL if Dungeon.is_all(id) else id


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
	_return_zoom = false
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


## Sets the first focus without showing a card: the card waits until the player looks.
func _first_focus(b: Button) -> void:
	if not is_instance_valid(b) or not b.is_inside_tree():
		return
	_quiet = true
	b.grab_focus(true)
	_quiet = false


# ── Places and their cards ───────────────────────────────────

## Makes a button a place: one visible card, its name for screen readers, its glow,
## and what going in does (`enter`, nothing for a closed place).
func _place(b: Button, title: String, line: String, color: Color, enter: Callable, tooltip: String = "") -> void:
	b.set_meta("card", [title, line, color])
	b.set_meta("enter", enter)
	b.accessibility_name = "%s: %s" % [title, line]
	if enter.is_valid() and not b.disabled:
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	# The card is the visible hover label. Keep richer context for assistive
	# technology without a second, native tooltip over the same marker.
	if tooltip != b.accessibility_name:
		b.accessibility_description = tooltip
	var glow := Glow.new()
	glow.name = "Glow"
	glow.size = b.size
	glow.round = b.size.x <= HIT + 1.0 and is_equal_approx(b.size.x, b.size.y)
	glow.visible = false
	b.add_child(glow)
	b.mouse_entered.connect(func():
		if not touch:
			show_card(b))
	b.mouse_exited.connect(func(): _let_go(b))
	b.focus_entered.connect(func():
		if not _quiet and not touch:
			show_card(b))
	b.focus_exited.connect(func(): _let_go(b))
	b.pressed.connect(press.bind(b))
	# A closed place has no press, but a tap still shows what it is.
	b.gui_input.connect(func(e: InputEvent):
		if b.disabled and (e is InputEventMouseButton or e is InputEventScreenTouch) and e.pressed:
			armed = b
			show_card(b))


## Route switches can trigger old hover/pressed signals while a layer is hiding.
func _active_place(b: Button) -> bool:
	if not is_instance_valid(b) or not b.is_visible_in_tree():
		return false
	var board := b.get_parent()
	return (screen == "world" and board == world_board) or (screen == "island" and board == island_board)


## A press on a place: on a touch screen the first one shows its card, then the next
## one goes in. With a mouse or a keyboard it goes in at once.
func press(b: Button) -> void:
	if _zooming or b.disabled or not _active_place(b):
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
	if _active_place(card_for) and not card_for.disabled:
		var enter: Callable = card_for.get_meta("enter")
		if enter.is_valid() and not _zooming:
			enter.call()


## Shows a place's card by it and lights the place. On an island the card goes beside
## the place, on the side with more room (its text shrunk to fit that side), because a
## column's places sit closer than a card is tall; it covers the ground beside while it
## shows. When it can't fit beside (the place in the middle), and on the world map, it
## goes above or below, whichever has more room.
func show_card(b: Button) -> void:
	if not _active_place(b):
		return
	var board := b.get_parent() as Control
	var card := board.get_node_or_null("Card") as Control
	if card == null:
		return
	if card_for != null and is_instance_valid(card_for) and card_for != b:
		(card_for.get_node("Glow") as Control).visible = false
	card_for = b
	(b.get_node("Glow") as Control).visible = true
	var info: Array = b.get_meta("card")
	var title := card.get_node("Box/Name") as Label
	title.text = info[0]
	title.add_theme_font_size_override("font_size", CARD_NAME)
	var line := card.get_node("Box/Line") as Label
	line.text = info[1]
	line.add_theme_font_size_override("font_size", UiTheme.SMALL)
	line.add_theme_color_override("font_color", info[2])
	# On a touch screen the first tap shows the card and the next one goes in (#186).
	var hint := card.get_node("Box/Hint") as Label
	hint.text = TAP_AGAIN
	hint.visible = touch and armed == b and not b.disabled
	card.visible = true
	card.reset_size()
	var r := Rect2(b.position, b.size)
	var gap := 14.0
	var edge := 12.0
	var frame: Rect2 = _map_frames[board]
	var left_room := r.position.x - gap - edge - frame.position.x
	var right_room := frame.end.x - r.end.x - gap - edge
	var room := maxf(left_room, right_room)
	if board == island_board and card.size.x > room and room > CARD_LEAST:
		var inside := room - (card.size.x - maxf(_width(title), _width(line)))
		_shrink_to(title, inside, CARD_NAME_LEAST)
		_shrink_to(line, inside, UiTheme.SMALL - 6)
		card.reset_size()
	var at := Vector2.ZERO
	if board == island_board and card.size.x <= room:
		at.x = r.end.x + gap if right_room >= left_room else r.position.x - gap - card.size.x
		at.y = r.get_center().y - card.size.y / 2.0
	else:
		var above := r.position.y - card.size.y - gap
		var below := r.end.y + gap
		at.y = above if above >= frame.position.y and (above - frame.position.y >= frame.end.y - below - card.size.y or board != island_board) else below
		if at.y + card.size.y > frame.end.y:
			at.y = r.get_center().y - card.size.y / 2.0
		at.x = r.get_center().x - card.size.x / 2.0
	card.position = at.clamp(frame.position + Vector2.ONE * edge, frame.end - card.size - Vector2.ONE * edge)


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
	var n := UiTheme.label("", CARD_NAME, UiTheme.TEXT)
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
	var h := UiTheme.label("", UiTheme.SMALL, UiTheme.SAND)
	h.name = "Hint"
	h.autowrap_mode = TextServer.AUTOWRAP_OFF
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.visible = false
	box.add_child(h)
	board.add_child(card)
	return card


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_active_touch[event.index] = true
		else:
			_active_touch.erase(event.index)
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
	_clear(world_board, 2)
	_frame_painting(world_board)
	var scrap := int(save.get("scrap", 0))
	(world.get_node("Header").get_child(0).get_node("Scrap") as Label).text = "Scrap: %d" % scrap
	for i in ISLANDS:
		var state := world_state(i.id)
		var open := state != "locked"
		var b := _zone_button(world_board, "Island_" + i.id, _world_zone(i.id, i.zone))
		b.disabled = not open
		var to := {"screen": "island", "island": i.id}
		var line: String = i.topic if open else "Coming soon"
		if state == "cleared":
			line += " · Cleared"
		_place(b, i.name, line, UiTheme.TEAL if open else UiTheme.DIM,
			(func(): _go_from_world(i.id, _island_point(i.id), go.bind(to))) if open else Callable(),
			"%s: %s" % [i.name, i.topic])
	var td_zone := _world_zone("thunderdome", THUNDERDOME_ZONE)
	var td := _zone_button(world_board, "Thunderdome", td_zone)
	td.disabled = not thunderdome_open()
	var td_at := td_zone.position * BOARD / 100.0
	_place(td, "Thunderdome", "Locked" if td.disabled else "Questions from all over the Wasteland", UiTheme.DIM if td.disabled else UiTheme.PINK,
		Callable() if td.disabled else (func(): _go_from_world(Dungeon.THUNDERDOME, td_at, go.bind(MapLink.THUNDERDOME_ROUTE))),
		"Thunderdome: opens once two places are open" if td.disabled else "")
	var lib := _zone_button(world_board, "RelicLibrary", _world_zone("relic-library", RELIC_LIBRARY_ZONE))
	_place(lib, "Relic Library", RELIC_LIBRARY_LINE, UiTheme.TEAL, func():
		MapLink.go(get_tree(), MapLink.RELIC_LIBRARY_ROUTE))
	var shop_zone := _world_zone("bazaar", BAZAAR_ZONE)
	var shop := _zone_button(world_board, "Bazaar", shop_zone)
	if not BAZAAR_PAINTED:
		var marker := Stall.new()
		marker.name = "Marker"
		marker.size = shop.size
		shop.add_child(marker)
	_place(shop, "Bazaar", "%d Scrap to spend" % scrap, UiTheme.SAND,
		func(): _go_from_world(HOME, shop_zone.position * BOARD / 100.0, open_bazaar),
		"Bazaar · %d Scrap to spend" % scrap)
	_card(world_board)
	_first_focus.call_deferred(world_board.get_node("Island_functions") as Button)


## A place's state on the world map, for its revealed card: "locked", "open" or "cleared". An island
## is cleared once its all-regions dungeon is (Progress.is_cleared(), as on the island's
## board); the Thunderdome waits for a second island. The optional Relic Library and
## Bazaar are always open.
func world_state(id: String) -> String:
	if id == Dungeon.THUNDERDOME:
		return "open" if thunderdome_open() else "locked"
	if id == HOME or id == "relic_library":
		return "open"
	if not island_open(id):
		return "locked"
	return "cleared" if Progress.is_cleared(save, Dungeon.all_of(id)) else "open"


## The place the player stands at on the world map: the save's "here" when it names a
## place that can be gone into, else the Bazaar.
func here() -> String:
	var id := String(save.get("here", HOME))
	if id == HOME or (id == Dungeon.THUNDERDOME and thunderdome_open()) or island_open(id):
		return id
	return HOME


## Goes into a place from the world map: records it as where the player is, then zooms in.
func _go_from_world(id: String, at: Vector2, then: Callable) -> void:
	if _zooming:
		return
	save["here"] = id
	SaveData.store(save, save_path)
	zoom_to(world_board, at, then)


## A single site-specific layer uses the source art's coordinates. It never
## enlarges, moves or consumes input from a registered landmark.
static func zone_ambient_key(id: String, wide: bool) -> String:
	return "zone_" + id + ("_wide" if wide else "")


# ── An island ────────────────────────────────────────────────

func _fill_island() -> void:
	_clear(island_board)
	_zone_ambient = null
	var info := island_info(route.island)
	var title := island.get_node("Header").get_child(0).get_node("Title") as Label
	title.text = info.name
	fit_title(title)
	var bg_path := background_path()
	var painted := bg_path != ""
	if painted:
		var art := TextureRect.new()
		art.name = "Art"
		art.texture = load(bg_path)
		art.set_meta("portrait", art.texture)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_SCALE
		art.size = BOARD
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		island_board.add_child(art)
		_frame_painting(island_board)
		# A fixture or future fallback has no authored registration.
		if art_dir == "":
			_zone_ambient = AmbientLayer.new()
			_zone_ambient.name = "ZoneAmbience"
			_zone_ambient.position = WIDE_FRAME.position if _wide_island else Vector2.ZERO
			_zone_ambient.size = WIDE_FRAME.size if _wide_island else BOARD
			_zone_ambient.modulate = scene_light.grade
			_zone_ambient.reduced_motion = reduced_motion()
			island_board.add_child(_zone_ambient)
			_zone_ambient.build(AmbientLayer.entries(AMBIENT, zone_ambient_key(route.island, _wide_island)))
	else:
		island_board.add_child(_coded_ground(route.island))
	var regions := MapLink.region_ids(route.island)
	pick = Progress.suggest(save, regions)
	var first: Button = null
	for id in regions:
		var b := _spot(id, Dungeon.region_name(id), spot_state(id), painted)
		if first == null or id == pick.get("region"):
			first = b
	var all := Dungeon.all_of(route.island)
	_spot(all, Dungeon.ALL_NAME, spot_state(all), painted)
	_spot("relic", "Relic device", "locked", painted)
	_card(island_board)
	_first_focus.call_deferred(first)


## The coded ground when there is no painting: the island's dusk gradient
## (ArtSlots.ground) and the jetty as a dot.
func _coded_ground(island_id: String) -> Control:
	var g := TextureRect.new()
	g.name = "Ground"
	g.texture = ArtSlots.ground(island_id)
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


## A registered landmark on the zone board. Paint is the permanent affordance;
## the card reveals status and suggestions on hover, focus or first touch.
func _spot(id: String, title: String, state: String, painted: bool = false) -> Button:
	var at := _spot_point(route.island, id)
	var relic := id == "relic"
	var d := RELIC_HIT if relic else HIT
	# The central core keeps the exact same anchor, but wide art has no
	# extra sky above it. Peripheral oversized hit squares remain entirely
	# on the painting; their centers and minimum useful size are unchanged.
	if _wide_island:
		var clearance := minf(at.y - WIDE_FRAME.position.y, WIDE_FRAME.end.y - at.y)
		d = minf(d, 2.0 * clearance)
	var b := Button.new()
	b.name = "Spot_" + spot_key(id)
	b.flat = true
	b.size = Vector2(d, d)
	b.position = at - b.size / 2.0
	var look := _landmark(id, state, d, painted)
	if look != null:
		b.add_child(look)
	island_board.add_child(b)
	if relic:
		b.disabled = true
		_place(b, title, "Closed for now", UiTheme.DIM, Callable(), "Relic device: lessons coming")
	else:
		var to := {"screen": "region", "island": route.island, "region": id}
		_place(b, title, spot_line(id, state), STATE_COLOR[state], func(): zoom_to(island_board, at, go.bind(to)))
	return b


static func _width(l: Label) -> float:
	var f := l.get_theme_font("font")
	return f.get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, l.get_theme_font_size("font_size")).x


## Takes a label's font size down until its text fits the width, or to `least`.
static func _shrink_to(l: Label, width: float, least: int = UiTheme.SMALL) -> void:
	var fs := l.get_theme_font_size("font_size")
	while fs > least and _width(l) > width:
		fs -= 2
		l.add_theme_font_size_override("font_size", fs)


## The line on a spot's card: "Coming soon", or how the player is doing there, and
## " · Spark's pick" on the pick.
func spot_line(id: String, state: String) -> String:
	if state == "locked":
		return "Coming soon"
	var pick_tag := " · Spark's pick" if id == pick.get("region") else ""
	var acc := Progress.accuracy(save, id)
	var best := Progress.best_floor(save, id)
	if acc.seen == 0 and best == 0:
		return "Not tried yet" + pick_tag
	var bits: Array = []
	if best > 0:
		bits.append("Mile %d" % best)
	if acc.seen > 0:
		bits.append("%d%% right" % acc.percent)
	if state == "cleared":
		bits.append("Cleared")
	return " · ".join(bits) + pick_tag


## The look of a spot in a state, filling its square: its landmark art, a fallback
## drawn only as scenery when the place is painted, or a compact fallback glyph tile in the state's colour with
## the region's glyph (mark()).
func _landmark(id: String, state: String, box: float, painted: bool) -> Control:
	var path := "%s%s-%s.png" % [island_art_dir(), spot_key(id), state]
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
	if Dungeon.is_all(id) and state != "locked":
		border = UiTheme.PINK
	var bg := UiTheme.PANEL if state != "locked" else Color(0.1, 0.12, 0.16, 0.85)
	holder.add_child(_glyph_tile(mark(spot_key(id)), box * (1.0 if Dungeon.is_all(id) else 0.8), border, bg))
	return holder


## A compact sign tile only on the unpainted fallback board.
func _glyph_tile(text: String, d: float, border: Color, bg: Color) -> Control:
	var ring := PanelContainer.new()
	ring.name = "Coded"
	ring.custom_minimum_size = Vector2(d, d)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(10)
	sb.set_corner_radius_all(12)
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


# ── The region screen ────────────────────────────────────────

func _fill_region() -> void:
	_clear(region_col)
	var id: String = route.region
	UiTheme.show_backdrop(region_backdrop, backdrop_for(id))
	var head := HBoxContainer.new()
	head.name = "Head"
	head.add_theme_constant_override("separation", 24)
	var back := Button.new()
	back.name = "Back"
	# The Thunderdome stands on the world map, not on an island.
	var dome: bool = id == Dungeon.THUNDERDOME
	back.text = "◂ The Wasteland" if dome else "◂ " + String(island_info(route.island).name)
	back.add_theme_font_size_override("font_size", UiTheme.SMALL)
	back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func(): go(MapLink.WORLD if dome else {"screen": "island", "island": route.island}))
	head.add_child(back)
	var title := UiTheme.label(Dungeon.region_name(id), 84, UiTheme.TEAL)
	title.name = "Title"
	title.add_theme_font_override("font", UiTheme.TITLE_FONT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	region_gap = Control.new()
	region_gap.name = "HudGap"
	region_gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	region_gap.custom_minimum_size.x = _region_hud_gap()
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
			region_col.add_child(UiTheme.label("No %s questions here yet. Another course has some: pick it above." % course.short, UiTheme.BODY, UiTheme.DIM))
		else:
			region_col.add_child(UiTheme.label("No questions here yet. This topic opens as soon as they're built.", UiTheme.BODY, UiTheme.DIM))

	region_col.add_child(ExamSwitch.make(bool(save.settings.get("exam_only", false)), func(on: bool):
		save.settings.exam_only = on
		SaveData.store(save, save_path)
		_fill_region()))

	if can_start(id, Courses.of(save)):
		var buttons := VBoxContainer.new()
		buttons.name = "Start"
		buttons.add_theme_constant_override("separation", 16)
		for f in Dungeon.start_floors(save, id):
			var b := Button.new()
			b.name = "Floor%d" % f
			b.text = "Start a run at mile 1" if f == 1 else "Start at mile %d · mile %d boss beaten" % [f, f - 1]
			b.add_theme_font_size_override("font_size", UiTheme.BIG)
			b.custom_minimum_size.y = 120
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			b.pressed.connect(func(): start_run(id, f))
			buttons.add_child(b)
		var p := Button.new()
		p.name = "Practice"
		p.text = "Practice · no timer, no damage"
		p.add_theme_font_size_override("font_size", UiTheme.BIG)
		p.custom_minimum_size.y = 120
		p.alignment = HORIZONTAL_ALIGNMENT_LEFT
		p.pressed.connect(func(): open_practice(id))
		buttons.add_child(p)
		region_col.add_child(buttons)
		(buttons.get_child(0) as Button).grab_focus.call_deferred()
	else:
		back.grab_focus.call_deferred()

	region_col.add_child(_stats_panel(id))
	region_col.add_child(_weak_panel(id))


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
		["BestFloor", "Furthest mile: %d" % best if best > 0 else "Furthest mile: no runs yet"],
		["Tried", "Different questions tried: %d of %d" % [cov.checked, cov.total]],
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
	col.add_child(UiTheme.label("Skills to work on", UiTheme.BIG, UiTheme.PINK))
	var weak := Progress.weakest_skills(save, id)
	if weak.is_empty():
		col.add_child(UiTheme.label("None yet. A skill shows here once you've answered it %d times." % Progress.MIN_ATTEMPTS, UiTheme.BODY, UiTheme.DIM))
	for w in weak:
		var l := UiTheme.label("• %s · %d%% right of %d" % [w.name, w.percent, w.seen], UiTheme.BODY)
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
