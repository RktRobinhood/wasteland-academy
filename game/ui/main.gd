extends Control
## The title screen. "Play" opens the map (ui/map.gd), "Practice" opens the practice
## screen and "Engine" the engine explorer. On the first load only, ?explore (see
## explorer.gd) goes to the explorer, a deep link to a run (see fight.gd) or a question
## (see practice.gd) goes straight there, and a map link such as #functions/quadratics
## (see engine/map_link.gd) opens the map there.

const PRACTICE := "res://scenes/practice.tscn"
const FIGHT := "res://scenes/fight.tscn"
const EXPLORER := "res://scenes/explorer.tscn"

static var _routed := false


func _ready() -> void:
	theme = UiTheme.make()
	var play := get_node_or_null("Center/Column/Buttons/Play") as Button
	if play != null:
		play.pressed.connect(open_map)
		play.grab_focus.call_deferred()
	var start := get_node_or_null("Center/Column/Buttons/Practice") as Button
	if start != null:
		start.pressed.connect(open_practice)
	var engine := get_node_or_null("Center/Column/Engine") as Button
	if engine != null:
		engine.pressed.connect(open_explorer)
	MapLink.listen(get_tree())
	if _routed:
		return
	_routed = true
	var practice := preload("res://ui/practice.gd")
	if practice.url_args().has("explore"):
		open_explorer.call_deferred()
	elif not preload("res://ui/fight.gd").deep_link().is_empty():
		open_fight.call_deferred()
	elif not practice.deep_link().is_empty():
		open_practice.call_deferred()
	elif MapLink.address() != "":
		get_tree().change_scene_to_file.call_deferred(MapLink.MAP)


func open_practice() -> void:
	get_tree().change_scene_to_file(PRACTICE)


## The world map, as a history entry, so the browser's back button returns here.
func open_map() -> void:
	MapLink.go(get_tree(), MapLink.WORLD)


func open_fight() -> void:
	get_tree().change_scene_to_file(FIGHT)


func open_explorer() -> void:
	get_tree().change_scene_to_file(EXPLORER)
