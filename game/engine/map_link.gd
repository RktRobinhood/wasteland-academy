class_name MapLink
extends RefCounted
## Links into the map (Q11 on the FAL-274 plan), so a teacher can post a region to a
## class: /next/#functions/quadratics opens that region's screen, /next/#functions the
## island, /next/#world the world map and /next/#bazaar the Bazaar (ui/bazaar.gd), which
## the world map links. Every island has links the same way (FAL-925): #algebra,
## #geometry/triangles, #stats/all (the island's all-regions dungeon). #thunderdome is
## the Thunderdome's screen, every island mixed. Anything else falls back to the world map.
##
##   MapLink.parse("#functions/quadratics")  # {"screen": "region", "island": "functions", "region": "quadratics"}
##   MapLink.parse("#calculus/all")          # {"screen": "region", "island": "calculus", "region": "all-calculus"}
##   MapLink.to_hash({"screen": "island", "island": "functions"})  # "#functions"
##   MapLink.island_of("kinematics")         # "calculus"
##
## On the web the hash is the route: going somewhere sets it (a browser history entry),
## and a hashchange (the back button, or a pasted link) sends the game there. On the
## desktop the route is just MapLink.current.

const MAP := "res://scenes/map.tscn"
const MAIN := "res://scenes/main.tscn"
const BAZAAR := "res://scenes/bazaar.tscn"
const WORLD := {"screen": "world"}
## The Bazaar is its own scene, but a map link all the same, so back leaves it.
const BAZAAR_ROUTE := {"screen": "bazaar"}
## Islands with a map, by link id -> catalogue topic: all five since FAL-925. A region is
## on the island of its syllabus topic (island_of).
const OPEN_ISLANDS := {"algebra": 1, "functions": 2, "geometry": 3, "stats": 4, "calculus": 5}
## Each island's music, and the Thunderdome's (audio/music_tracks.gd); "-boss" is an
## island's boss loop. The Thunderdome has one loop, bosses too.
const MUSIC := {"algebra": "scrap-fields", "functions": "signal-tower", "geometry": "dry-flats",
	"stats": "radio-spires", "calculus": "engine-core", "thunderdome": "thunderdome"}
## The Thunderdome's screen: a region screen for the all-islands dungeon, off the world map.
## Its island and its region are both Dungeon.THUNDERDOME, and its link is #thunderdome.
const THUNDERDOME_ROUTE := {"screen": "region", "island": Dungeon.THUNDERDOME, "region": Dungeon.THUNDERDOME}

## The route on screen (or about to be); {} before the map has opened.
static var current: Dictionary = {}
static var _tree: SceneTree
static var _on_hash = null
## Region id -> island id, read from the catalogue once.
static var _islands := {}


## The route a link asks for. Case, slashes and spaces around it don't matter.
static func parse(link: String) -> Dictionary:
	var s := link.strip_edges().trim_prefix("#").trim_prefix("/").trim_suffix("/").to_lower()
	if s == "bazaar":
		return BAZAAR_ROUTE.duplicate()
	if s == Dungeon.THUNDERDOME:
		return THUNDERDOME_ROUTE.duplicate()
	var parts := s.split("/")
	if parts.size() < 1 or parts.size() > 2 or not OPEN_ISLANDS.has(parts[0]):
		return WORLD.duplicate()
	if parts.size() == 1:
		return {"screen": "island", "island": parts[0]}
	if parts[1] == Dungeon.ALL:
		return {"screen": "region", "island": parts[0], "region": Dungeon.all_of(parts[0])}
	# A region only on its own island's link: #algebra/quadratics is junk.
	if not region_ids(parts[0]).has(parts[1]):
		return WORLD.duplicate()
	return {"screen": "region", "island": parts[0], "region": parts[1]}


static func to_hash(route: Dictionary) -> String:
	match route.get("screen", "world"):
		"island":
			return "#" + String(route.island)
		"region":
			if route.region == Dungeon.THUNDERDOME:
				return "#" + Dungeon.THUNDERDOME
			return "#%s/%s" % [route.island, Dungeon.ALL if Dungeon.is_all(route.region) else route.region]
		"bazaar":
			return "#bazaar"
	return "#world"


## The scene a route is shown in: the Bazaar's own, or the map's.
static func scene_for(route: Dictionary) -> String:
	return BAZAAR if route.get("screen", "") == "bazaar" else MAP


## The catalogue's region ids on an island (every island's, for ""), each island's in the
## plan's order (the catalogue's `order`: most-examined first), islands by topic.
static func region_ids(island: String = "") -> Array:
	var regions: Array = QuestionEngine.catalogue().get("regions", []).filter(func(r):
		return island == "" or _island_of_topic(region_topic(r)) == island)
	regions.sort_custom(func(a, b):
		var ta := region_topic(a)
		var tb := region_topic(b)
		return ta < tb if ta != tb else int(a.get("order", 99)) < int(b.get("order", 99)))
	return regions.map(func(r): return String(r.id))


## A catalogue region's topic: the topic of its syllabus subtopics ("2.6" is topic 2).
static func region_topic(r: Dictionary) -> int:
	var syl: Array = r.get("syllabus", [])
	return int(String(syl[0]).get_slice(".", 0)) if not syl.is_empty() else 0


## The island a region is on: its topic's island, the island an all-regions dungeon names,
## or the Thunderdome for its own dungeon. A region the catalogue doesn't list (a test's)
## is on the Functions island.
static func island_of(region: String) -> String:
	if region == Dungeon.THUNDERDOME:
		return Dungeon.THUNDERDOME
	if Dungeon.is_all(region):
		return Dungeon.island_of_all(region)
	if _islands.is_empty():
		for r in QuestionEngine.catalogue().get("regions", []):
			_islands[String(r.id)] = _island_of_topic(region_topic(r))
	return String(_islands.get(region, "functions"))


static func _island_of_topic(topic: int) -> String:
	for id in OPEN_ISLANDS:
		if OPEN_ISLANDS[id] == topic:
			return id
	return "functions"


## The loop for a region's island, or its boss loop during a mini-boss or boss (where the
## place has one: the Thunderdome keeps its own loop).
static func music_for(region: String, boss := false) -> String:
	var cue := String(MUSIC.get(island_of(region), MUSIC.functions))
	return cue + "-boss" if boss and MusicTracks.CUES.has(cue + "-boss") else cue


## The route of a region's screen.
static func region_route(region: String) -> Dictionary:
	if region == Dungeon.THUNDERDOME:
		return THUNDERDOME_ROUTE.duplicate()
	return {"screen": "region", "island": island_of(region), "region": region}


## Back to the title screen, clearing the map from the address bar.
static func home(tree: SceneTree) -> void:
	current = {}
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.history.replaceState(null, '', window.location.pathname + window.location.search)")
	tree.change_scene_to_file(MAIN)


## The hash in the address bar (web), or --map=<link> on the command line, or "".
static func address() -> String:
	if OS.has_feature("web"):
		var h = JavaScriptBridge.eval("window.location.hash", true)
		if h is String and h != "":
			return h
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--map="):
			return a.substr(6)
	return ""


## Shows a route: records it, writes it to the address bar (a history entry, unless
## `replace`) and opens its scene (scene_for) if it isn't already open.
static func go(tree: SceneTree, route: Dictionary, replace := false) -> void:
	current = route.duplicate()
	listen(tree)
	_write(route, replace)
	_show(tree, tree.current_scene, current, false)


## Shows a route in the scene on screen when that scene draws it, or opens its scene,
## quitting a run in progress first when `leave`.
static func _show(tree: SceneTree, scene: Node, route: Dictionary, leave: bool) -> void:
	var want := scene_for(route)
	if scene != null and scene.scene_file_path == want and want == BAZAAR:
		return
	if want == MAP and scene != null and scene.has_method("show_route"):
		scene.show_route(route)
	else:
		if leave:
			_leave(scene)
		tree.change_scene_to_file(want)


static func _write(route: Dictionary, replace: bool) -> void:
	if not OS.has_feature("web"):
		return
	var h := to_hash(route)
	if JavaScriptBridge.eval("window.location.hash", true) == h:
		return
	if replace:
		JavaScriptBridge.eval("window.history.replaceState(null, '', %s)" % JSON.stringify(h))
	else:
		JavaScriptBridge.eval("window.location.hash = %s" % JSON.stringify(h))


## Follows the address bar from now on (web only; once).
static func listen(tree: SceneTree) -> void:
	_tree = tree
	if not OS.has_feature("web") or _on_hash != null:
		return
	_on_hash = JavaScriptBridge.create_callback(_hash_changed)
	JavaScriptBridge.get_interface("window").addEventListener("hashchange", _on_hash)


## The back button or a pasted link. An empty hash is the title screen. A run in
## progress is quit first, so its Scrap is banked.
static func _hash_changed(_args: Array) -> void:
	if _tree == null:
		return
	var h := address()
	var scene := _tree.current_scene
	if h == "":
		current = {}
		if scene != null and scene.scene_file_path != MAIN:
			_leave(scene)
			_tree.change_scene_to_file(MAIN)
		return
	var route := parse(h)
	if route == current and scene != null and scene.scene_file_path == scene_for(route):
		return
	current = route
	_show(_tree, scene, route, true)


static func _leave(scene: Node) -> void:
	if scene != null and scene.has_method("leave_run"):
		scene.leave_run()
