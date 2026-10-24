extends Control
## The title screen. "Practice" opens the practice screen; a deep link to a question
## (see practice.gd) goes straight there.

const PRACTICE := "res://scenes/practice.tscn"


func _ready() -> void:
	theme = UiTheme.make()
	var start := get_node_or_null("Center/Column/Practice") as Button
	if start != null:
		start.pressed.connect(open_practice)
		start.grab_focus.call_deferred()
	if not preload("res://ui/practice.gd").deep_link().is_empty():
		open_practice.call_deferred()


func open_practice() -> void:
	get_tree().change_scene_to_file(PRACTICE)
