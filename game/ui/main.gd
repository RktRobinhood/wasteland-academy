extends Control
## The title screen. "Play" opens the Quadratics floor select (the map, G5, replaces it),
## "Practice" opens the practice screen, "Bazaar" the Bazaar (G6, until the map links it)
## and "Engine" the engine explorer. On the first load only, ?explore (see explorer.gd)
## goes to the explorer, and a deep link to the Bazaar (see bazaar.gd), a run (see
## fight.gd) or a question (see practice.gd) goes straight there.

const PRACTICE := "res://scenes/practice.tscn"
const FIGHT := "res://scenes/fight.tscn"
const EXPLORER := "res://scenes/explorer.tscn"
const BAZAAR := "res://scenes/bazaar.tscn"

static var _routed := false


func _ready() -> void:
	theme = UiTheme.make()
	var play := get_node_or_null("Center/Column/Buttons/Play") as Button
	if play != null:
		play.pressed.connect(open_fight)
		play.grab_focus.call_deferred()
	var start := get_node_or_null("Center/Column/Buttons/Practice") as Button
	if start != null:
		start.pressed.connect(open_practice)
	var bazaar := get_node_or_null("Center/Column/Buttons/Bazaar") as Button
	if bazaar != null:
		bazaar.pressed.connect(open_bazaar)
	var engine := get_node_or_null("Center/Column/Engine") as Button
	if engine != null:
		engine.pressed.connect(open_explorer)
	if _routed:
		return
	_routed = true
	var practice := preload("res://ui/practice.gd")
	if practice.url_args().has("explore"):
		open_explorer.call_deferred()
	elif preload("res://ui/bazaar.gd").deep_link() != "":
		open_bazaar.call_deferred()
	elif not preload("res://ui/fight.gd").deep_link().is_empty():
		open_fight.call_deferred()
	elif not practice.deep_link().is_empty():
		open_practice.call_deferred()


func open_practice() -> void:
	get_tree().change_scene_to_file(PRACTICE)


func open_fight() -> void:
	get_tree().change_scene_to_file(FIGHT)


func open_explorer() -> void:
	get_tree().change_scene_to_file(EXPLORER)


func open_bazaar() -> void:
	get_tree().change_scene_to_file(BAZAAR)
