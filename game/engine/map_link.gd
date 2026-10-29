class_name MapLink
extends RefCounted
## Links into the map (Q11 on the FAL-274 plan), so a teacher can post a region to a
## class: /next/#functions/quadratics opens that region's screen, /next/#functions the
## island, /next/#world the world map and /next/#bazaar the Bazaar (ui/bazaar.gd), which
## the world map links. Anything else falls back to the world map.
##
##   MapLink.parse("#functions/quadratics")  # {"screen": "region", "island": "functions", "region": "quadratics"}
##   MapLink.to_hash({"screen": "island", "island": "functions"})  # "#functions"
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
## Islands with a map, by link id -> catalogue topic. The others are "coming later".
const OPEN_ISLANDS := {"functions": 2}
## Each open island's music (audio/music_tracks.gd); "-boss" is its boss loop.
const MUSIC := {"functions": "signal-tower"}

## The route on screen (or about to be); {} before the map has opened.
static var current: Dictionary = {}
static var _tree: SceneTree
static var _on_hash = null


## The route a link asks for. Case, slashes and spaces around it don't matter.
static func parse(link: String) -> Dictionary:
	var s := link.strip_edges().trim_prefix("#").trim_prefix("/").trim_suffix("/").to_lower()
	if s == "bazaar":
		return BAZAAR_ROUTE.duplicate()
	var parts := s.split("/")
	if parts.size() < 1 or parts.size() > 2 or not OPEN_ISLANDS.has(parts[0]):
		return WORLD.duplicate()
	if parts.size() == 1:
		return {"screen": "island", "island": parts[0]}
	if not region_ids().has(parts[1]) and parts[1] != Dungeon.ALL:
		return WORLD.duplicate()
	return {"screen": "region", "island": parts[0], "region": parts[1]}


static func to_hash(route: Dictionary) -> String:
	match route.get("screen", "world"):
		"island":
			return "#" + String(route.island)
		"region":
			return "#%s/%s" % [route.island, route.region]
		"bazaar":
			return "#bazaar"
	return "#world"


## The scene a route is shown in: the Bazaar's own, or the map's.
static func scene_for(route: Dictionary) -> String:
	return BAZAAR if route.get("screen", "") == "bazaar" else MAP


## The catalogue's region ids, in the plan's order (the catalogue's `order`).
static func region_ids() -> Array:
	var regions: Array = QuestionEngine.catalogue().get("regions", []).duplicate()
	regions.sort_custom(func(a, b): return int(a.get("order", 99)) < int(b.get("order", 99)))
	return regions.map(func(r): return String(r.id))


## The island a region is on: every catalogue region is on the Functions island today.
static func island_of(_region: String) -> String:
	return "functions"


## The loop for a region's island, or its boss loop during a mini-boss or boss.
static func music_for(region: String, boss := false) -> String:
	return String(MUSIC[island_of(region)]) + ("-boss" if boss else "")


## The route of a region's screen.
static func region_route(region: String) -> Dictionary:
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
