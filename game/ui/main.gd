extends Control
## The title screen. "Practice" opens the practice screen and "Engine" the engine
## explorer. A deep link to a question (see practice.gd) goes straight to practice, and
## ?explore (see explorer.gd) to the explorer, on the first load only.

const PRACTICE := "res://scenes/practice.tscn"
const EXPLORER := "res://scenes/explorer.tscn"

static var _routed := false


func _ready() -> void:
	theme = UiTheme.make()
	var start := get_node_or_null("Center/Column/Practice") as Button
	if start != null:
		start.pressed.connect(open_practice)
		start.grab_focus.call_deferred()
	var engine := get_node_or_null("Center/Column/Engine") as Button
	if engine != null:
		engine.pressed.connect(open_explorer)
	if _routed:
		return
	_routed = true
	var practice := preload("res://ui/practice.gd")
	if practice.url_args().has("explore"):
		open_explorer.call_deferred()
	elif not practice.deep_link().is_empty():
		open_practice.call_deferred()


func open_practice() -> void:
	get_tree().change_scene_to_file(PRACTICE)


func open_explorer() -> void:
	get_tree().change_scene_to_file(EXPLORER)
