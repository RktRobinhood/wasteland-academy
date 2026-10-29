extends Control
## The title screen. "Practice" opens the practice screen; a deep link to a question
## (see practice.gd) goes straight there, and ?journey=demo opens the journey demo
## (ui/journey_demo.gd).

const PRACTICE := "res://scenes/practice.tscn"
const JOURNEY_DEMO := "res://scenes/journey_demo.tscn"


func _ready() -> void:
	theme = UiTheme.make()
	var start := get_node_or_null("Center/Column/Practice") as Button
	if start != null:
		start.pressed.connect(open_practice)
		start.grab_focus.call_deferred()
	if preload("res://ui/journey_demo.gd").url_args().get("journey", "") == "demo":
		get_tree().change_scene_to_file.call_deferred(JOURNEY_DEMO)
	elif not preload("res://ui/practice.gd").deep_link().is_empty():
		open_practice.call_deferred()


func open_practice() -> void:
	get_tree().change_scene_to_file(PRACTICE)
